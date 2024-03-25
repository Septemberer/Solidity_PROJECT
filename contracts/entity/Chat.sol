// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IChat.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Message.sol";

contract Chat is IChat, Ownable, ReentrancyGuard, Initializable {

    address public initiator_user;
    address public target_user;
    uint256 public initialize_timestamp;

    Message[] private out_msg;
    Message[] private in_msg;

    bool private initialized;

    modifier isDeployer() {
        require(initiator_user == _msgSender(), "caller not deployer");
        _;
    }

    event InMsg(address indexed user, Message message);
    event OutMsg(address indexed user, Message message);

    constructor(){}

    function initialize(
        address _target_user,
        address _initiator_user
    ) public override initializer {
        require(_target_user != address(0), "Not null");
        require(_initiator_user != address(0), "Not null");
        target_user = _target_user;
        initiator_user = _initiator_user;
        initialize_timestamp = block.timestamp;
    }

    function send(uint256[] _data) public external nonReentrant {
        require(_data.length > 0, "You can't text none");
        require(_msgSender() == initiator_user, "Not SEND");

        Message message = new Message(_msgSender(), target_user, _data);

        require(message.create_timestamp() >= initialize_timestamp, "TIME ERROR");

        out_msg.push(message);
        emit OutMsg(_msgSender(), message);
    }

    function get(uint256[] _data) public external nonReentrant {
        require(_data.length > 0, "You can't text none");
        require(_msgSender() == target_user, "Not SEND");

        Message message = new Message(_msgSender(), initiator_user, _data);

        require(message.create_timestamp() >= initialize_timestamp, "TIME ERROR");

        in_msg.push(message);
        emit InMsg(_msgSender(), message);
    }

    function getAllChatData() public view returns (uint256[] allData) {
        int in = 0;
        int out = 0;
        for (int i = 0; i < in_msg.length + out_msg.length - 1 ; i++) {
            if (in < in_msg.length && in_msg[in].create_timestamp() <= out_msg[out].create_timestamp()) {
                allData.push(in_msg[in].data());
                in++;
            } else {
                allData.push(out_msg[out].data());
                out++;
            }
        }
        return allData;
    }

    function whatTime() public view returns (uint256) {
        return block.timestamp;
    }

}
