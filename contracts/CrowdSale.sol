// SPDX-License-Identifier: MIT

import "./resources/pancake-swap/interfaces/IPancakeRouter02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/IStaking.sol";

pragma solidity ^0.8.4;

contract CrowdSale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    IPancakeRouter02 public UV2Router; // Для использования функции добавления ликвидности

    IStaking public staking; // Отсюда будем подтягивать информацию об уровне пользователей

    uint256 public price; // Цена saleToken выраженная в paymentToken 10^10

    IERC20Metadata public paymentToken; // Токены использующиеся для накопления инвестиций

    IERC20Metadata public saleToken; // Токены которые мы продаем

    uint256 public percentDEX; // Процент пула, который будет использоваться для обеспечения ликвидности

    uint256 public timeStart; // Время открытия функций для инвестирования

    uint256 public timeEnd; // Время закрытия функций инвестирования
    // только после этого времени возможно добавление ликвидности

    bool public finalized; // Была ли добавлена ликвидность

    struct PartPool {
        uint256 maxSizePart;
        uint256 currentSizePart;
    }

    mapping(address => uint256) payments;

    mapping(uint256 => PartPool) pool;

    modifier wasFinalized() {
        require(finalized, "Liquidity has not been added yet");
        _;
    }

    event Buy(address indexed user, uint256 amount);
    event Sell(address indexed user, uint256 amount);

    /**
     * @notice Create contract
     * @param _paymentToken: Токены использующиеся для накопления инвестиций
     * @param _saleToken: Токены которые мы продаем
     * @param _staking: Стейкинг привязанный к продажам
     * @param _price: Цена saleToken выраженная в paymentToken
     * @param _timePeriod: Сколько будет длиться период продаж
     * @param _poolSize: Размер пула который будет участвовать а продажах
     * @param _percentDEX: Процент продающегося пула, который будет использоваться для ликвидности
     */
    constructor(
        IERC20Metadata _paymentToken,
        IERC20Metadata _saleToken,
        IStaking _staking,
        IPancakeRouter02 _UV2Router,
        uint256 _price,
        uint256 _timePeriod,
        uint256 _poolSize,
        uint256 _percentDEX
    ) {
        paymentToken = _paymentToken;
        saleToken = _saleToken;
        uint256 decimalsSaleToken = uint256(_saleToken.decimals());
        uint256 decimalsPaymentToken = uint256(_paymentToken.decimals());
        price = _price * (10**(decimalsSaleToken - decimalsPaymentToken));
        timeStart = block.timestamp;
        timeEnd = timeStart + _timePeriod;
        percentDEX = _percentDEX;
        _initPool(_poolSize);
        staking = _staking;
        UV2Router = _UV2Router;
    }

    /**
     * @notice Возвращает проданную часть пула
     */
    function soldPoolInfo() public view returns (uint256) {
        return ((pool[1].maxSizePart - pool[1].currentSizePart) +
            (pool[2].maxSizePart - pool[2].currentSizePart) +
            (pool[3].maxSizePart - pool[3].currentSizePart) +
            (pool[4].maxSizePart - pool[4].currentSizePart) +
            (pool[5].maxSizePart - pool[5].currentSizePart));
    }

    /**
     * @notice Возвращает непроданную часть пула
     */
    function unSoldPoolInfo() public view returns (uint256) {
        return (pool[1].currentSizePart +
            pool[2].currentSizePart +
            pool[3].currentSizePart +
            pool[4].currentSizePart +
            pool[5].currentSizePart);
    }

    /**
     * @notice Для покупки токенов юзерами в течение промежутка продажи
     * @param _amountPay: сколько готов инвестировать юзер
     */
    function buy(uint256 _amountPay) external nonReentrant {
        require(block.timestamp < timeEnd, "Crowd Sale ended");
        require(_amountPay > 0, "You can't buy zero");

        address _user = _msgSender();
        uint256 _lvl = staking.getLevelInfo(_user);
        uint256 _amountSale = _getSellAmount(_amountPay);

        require(pool[_lvl].currentSizePart >= _amountSale, "Limit exceeded");

        pool[_lvl].currentSizePart -= _amountSale;
        payments[_user] += _amountPay;
        paymentToken.safeTransferFrom(_user, address(this), _amountPay);
        emit Buy(_user, _amountPay);
    }

    function whatTime() public view returns (uint256) {
        return block.timestamp;
    }

    function inside() public view returns (bool) {
        return timeStart < whatTime() && whatTime() < timeEnd;
    }

    /**
     * @notice Начисляет юзеру приобретенные токены, может использоваться только после добавления ликвидности
     */
    function getTokens() external nonReentrant wasFinalized {
        address user = _msgSender();
        uint256 amountSell = _getSellAmount(payments[user]);
        require(amountSell > 0, "You have nothing to take off");
        payments[user] = 0;
        saleToken.transfer(user, amountSell);
        emit Sell(user, amountSell);
    }

    /**
     * @notice Начисляет владельцу инвестированные пользователями токены, может использоваться только после добавления ликвидности
     */
    function widthdrawSaleTokens()
        external
        nonReentrant
        onlyOwner
        wasFinalized
    {
        address owner = _msgSender();
        uint256 amountSell = unSoldPoolInfo();
        saleToken.transfer(owner, amountSell);
        emit Sell(owner, amountSell);
    }

    /**
     * @notice Начисляет владельцу непроданные токены, может использоваться только после добавления ликвидности
     */
    function widthdrawPaymentTokens()
        external
        nonReentrant
        onlyOwner
        wasFinalized
    {
        address owner = _msgSender();
        uint256 amountPayment = paymentToken.balanceOf(address(this));
        paymentToken.transfer(owner, amountPayment);
        emit Sell(owner, amountPayment);
    }

    /**
     * @notice Добавляет ликвидность, используется после закрытия торгов, открывает возможность забрать купленные токены
     */
    function finalize() external nonReentrant onlyOwner {
        require(block.timestamp > timeEnd, "Crowd Sale not ended");

        uint256 amountPT = (percentDEX * soldPoolInfo()) / 100;

        UV2Router.addLiquidity(
            address(saleToken),
            address(paymentToken),
            amountPT / price,
            amountPT,
            1,
            1,
            address(this),
            block.timestamp + 60 * 60 // Запас час на проведение транзакции
        );
        finalized = true;
    }

    /**
     * @notice Инициализатор пула, выделяет слоты в пуле для юзеров различных уровней
     * @param poolSize: Размер пула, который будет использоваться для продажи
     */
    function _initPool(uint256 poolSize) internal {
        pool[1] = PartPool((poolSize * 5) / 100, (poolSize * 5) / 100);
        pool[2] = PartPool((poolSize * 10) / 100, (poolSize * 10) / 100);
        pool[3] = PartPool((poolSize * 15) / 100, (poolSize * 15) / 100);
        pool[4] = PartPool((poolSize * 30) / 100, (poolSize * 30) / 100);
        pool[5] = PartPool((poolSize * 40) / 100, (poolSize * 40) / 100);
    }

    function _getSellAmount(uint256 _paymentAmount)
        internal
        view
        returns (uint256)
    {
        uint256 decimalsSaleToken = uint256(saleToken.decimals());
        uint256 decimalsPaymentToken = uint256(paymentToken.decimals());
        uint256 _price = price *
            (10**(decimalsSaleToken - decimalsPaymentToken));
        return _paymentAmount / _price;
    }
}
