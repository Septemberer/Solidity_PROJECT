// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/IStaking.sol";

pragma solidity ^0.8.4;

contract CrowdSale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    IStaking public staking;

    IERC20Metadata public paymentToken;

    uint256 public price;

    IERC20Metadata public saleToken;

    uint256 public timeStart;

    uint256 public timeEnd;

    struct PartPool {
        uint256 maxSizePart;
        uint256 currentSizePart;
    }

    mapping(uint256 => PartPool) pool;

    constructor (
        IERC20Metadata _paymentToken,
        IERC20Metadata _saleToken,
        uint256 _price,
        uint256 _timePeriod
    ) {
        paymentToken = _paymentToken;
        saleToken = _saleToken;
        price = _price;
        timeStart = block.timestamp;
        timeEnd = timeStart + _timePeriod;
    }

    function initPool (uint256 poolSize) external onlyOwner{
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

}