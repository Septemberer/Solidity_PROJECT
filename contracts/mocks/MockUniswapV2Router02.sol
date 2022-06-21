// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";

contract MockUniswapV2Router02 is UniswapV2Router02 {
    address public immutable override factory;
    address public immutable override WETH;

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }
}
