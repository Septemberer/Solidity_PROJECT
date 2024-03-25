// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Message is Ownable, ReentrancyGuard, Initializable {

    address public sender;
    address public target;
    uint256[] public data;
    uint256 public create_timestamp;

    constructor(address _sender, address _target, uint256[] _data){
        require(_sender != address(0), "Not null");
        require(_target != address(0), "Not null");
        sender = _sender;
        target = _target;
        data = _data;
        create_timestamp = block.timestamp;
    }
}
