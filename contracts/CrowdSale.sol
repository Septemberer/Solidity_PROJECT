// SPDX-License-Identifier: MIT

import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/IStaking.sol";

pragma solidity ^0.8.4;

contract CrowdSale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    UniswapV2Router02 public UV2Router;

    IStaking public staking;

    IERC20Metadata public paymentToken;

    uint256 public price; // payment/sale

    IERC20Metadata public saleToken;

    uint256 public timeStart;

    uint256 public timeEnd;

    struct PartPool {
        uint256 maxSizePart;
        uint256 currentSizePart;
    }

    struct Payment {
        address user;
        uint256 amountPayment;
        uint256 timestamp;
    }

    Payment[] payments;

    mapping(uint256 => PartPool) pool;

    constructor (
        IERC20Metadata _paymentToken,
        IERC20Metadata _saleToken,
        uint256 _price,
        uint256 _timePeriod,
        uint256 _poolSize
    ) {
        paymentToken = _paymentToken;
        saleToken = _saleToken;
        price = _price;
        timeStart = block.timestamp;
        timeEnd = timeStart + _timePeriod;
        initPool(_poolSize);
    }

    function soldPoolInfo () public view returns (uint256) {
        return (
            (pool[1].maxSizePart - pool[1].currentSizePart) +
            (pool[2].maxSizePart - pool[2].currentSizePart) +
            (pool[3].maxSizePart - pool[3].currentSizePart) +
            (pool[4].maxSizePart - pool[4].currentSizePart) +
            (pool[5].maxSizePart - pool[5].currentSizePart)
        );
    }

    function initPool (uint256 poolSize) internal {
        pool[1] = PartPool (
            poolSize * 5 / 100,
            poolSize * 5 / 100
        );
        pool[2] = PartPool (
            poolSize * 10 / 100,
            poolSize * 10 / 100
        );
        pool[3] = PartPool (
            poolSize * 15 / 100,
            poolSize * 15 / 100
        );
        pool[4] = PartPool (
            poolSize * 30 / 100,
            poolSize * 30 / 100
        );
        pool[5] = PartPool (
            poolSize * 40 / 100,
            poolSize * 40 / 100
        );
    }

    function buy (uint256 _amountPay) external nonReentrant {

        require(block.timestamp < timeEnd, "Crowd Sale ended");

        address _user = _msgSender();
        uint256 _lvl = staking.getLevelInfo(_user);
        
        if (_amountPay > 0) {
            uint256 _amountSale = price * _amountPay;
            require(pool[_lvl].currentSizePart >= _amountSale, "Limit exceeded");
            pool[_lvl].currentSizePart -= _amountSale;

            paymentToken.safeTransferFrom(
                _user,
                address(this),
                _amountPay
            );
            
            payments.push(Payment(
                _user,
                _amountPay,
                block.timestamp
            ));
        }
    }

    function finalize () external nonReentrant onlyOwner {
        require(block.timestamp > timeEnd, "Crowd Sale not ended");

        uint256 amountPT = soldPoolInfo();
        UV2Router.addLiquidity(
            saleToken, 
            paymentToken, 
            amountPT * price, 
            amountPT, 
            1, 
            1, 
            address(this), 
            block.timestamp + 60 * 60 // Запас час на проведение транзакции
        );

        for (uint i; i < payments.length; i++){
            if (payments[i].timestamp < timeEnd) {
                saleToken.transfer(
                    payments[i].user,
                    payments[i].amountPayment
                );
            }
        }
    }
}