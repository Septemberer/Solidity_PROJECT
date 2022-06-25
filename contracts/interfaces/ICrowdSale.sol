// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../resources/pancake-swap/interfaces/IPancakeRouter02.sol";
import "contracts/interfaces/IStaking.sol";

interface ICrowdSale {

    struct PartPool {
        uint256 maxSizePart;
        uint256 currentSizePart;
    }

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
    function initialize(
        IERC20Metadata _paymentToken,
        IERC20Metadata _saleToken,
        IStaking _staking,
        IPancakeRouter02 _UV2Router,
        uint256 _price,
        uint256 _timePeriod,
        uint256 _poolSize,
        uint256 _percentDEX,
        address _deployer
    ) external;
}
