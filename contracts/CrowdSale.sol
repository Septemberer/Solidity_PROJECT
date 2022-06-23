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

    IPancakeRouter02 public UV2Router; // To use the add liquidity function

    IStaking public staking; // From here we will pull up information about the user level

    uint256 public price; // saleToken price expressed in paymentToken

    IERC20Metadata public paymentToken; // Tokens used to accumulate investments

    IERC20Metadata public saleToken; // Tokens that we sell

    uint256 public percentDEX; // The percentage of the pool that will be used to provide liquidity

    uint256 public timeStart; // Opening time of functions for investment

    uint256 public timeEnd; // Closing time of investment functions
    // only after this time is it possible to add liquidity

    bool public finalized; // Has liquidity been added

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
     * @param _paymentToken: Tokens used to accumulate investments
     * @param _saleToken: Tokens that we sell
     * @param _staking: Stacking linked to sales
     * @param _price: saleToken price expressed in paymentToken
     * @param _timePeriod: How long will the sales period last
     * @param _poolSize: The size of the pool that will participate in sales
     * @param _percentDEX: Percentage of the pool being sold that will be used for liquidity
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
     * @notice Returns the sold part of the pool
     */
    function soldPoolInfo() public view returns (uint256) {
        return ((pool[1].maxSizePart - pool[1].currentSizePart) +
            (pool[2].maxSizePart - pool[2].currentSizePart) +
            (pool[3].maxSizePart - pool[3].currentSizePart) +
            (pool[4].maxSizePart - pool[4].currentSizePart) +
            (pool[5].maxSizePart - pool[5].currentSizePart));
    }

    /**
     * @notice Returns the unsold part of the pool
     */
    function unSoldPoolInfo() public view returns (uint256) {
        return (pool[1].currentSizePart +
            pool[2].currentSizePart +
            pool[3].currentSizePart +
            pool[4].currentSizePart +
            pool[5].currentSizePart);
    }

    /**
     * @notice For the purchase of tokens by users during the period of sale
     * @param _amountPay: how much is the user willing to invest
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
     * @notice Accrues the purchased tokens to the user, can be used only after adding liquidity
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
     * @notice Accrues tokens invested by users to the owner, can be used only after adding liquidity
     */
    function widthdrawSellTokens()
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
     * @notice Accrues unsold tokens to the owner, can be used only after adding liquidity
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
     * @notice Adds liquidity, is used after the close of trading, opens the opportunity to pick up the purchased tokens
     */
    function finalize() external nonReentrant onlyOwner {
        require(block.timestamp > timeEnd, "Crowd Sale not ended");

        uint256 amountPT = (percentDEX * soldPoolInfo()) / 100;
        uint256 amountST = _getSellAmount(amountPT);
        saleToken.approve(address(UV2Router), amountST);
        paymentToken.approve(address(UV2Router), amountPT);
        UV2Router.addLiquidity(
            address(saleToken),
            address(paymentToken),
            amountST,
            amountPT,
            0,
            0,
            address(this),
            block.timestamp + 60 * 60 // Reserve an hour for conducting a transaction
        );
        finalized = true;
    }

    /**
     * @notice Pool initializer, allocates slots in the pool for users of various levels
     * @param poolSize: The size of the pool to be used for sale
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
