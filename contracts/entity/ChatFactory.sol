// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IChat.sol";

contract ChatFactory is Ownable, ReentrancyGuard {

    address public implementation;
    address[] public allChat;

    mapping(bytes32 => address) private idToAddress;

    function setImpl(address _implementation) external onlyOwner {
        require(
            implementation == address(0),
            "Contract instance has already been implemented"
        );
        require(_implementation != address(0), "Incorrect Impl");
        implementation = _implementation;
    }

    function createChatContract(
        address _target_user,
        address _initiator_user
    ) external payable nonReentrant returns (address chatContract) {
        require(
            implementation != address(0),
            "Contract instance has already been implemented"
        );
        bytes32 id = _getOptionId(
            _target_user,
            _initiator_user);

        require(idToAddress[id] == address(0), "Crowd sourcing type exist");

        chatContract = Clones.clone(implementation);

        IChat(chatContract).initialize(
            _target_user,
            _initiator_user
        );
        allChat.push(chatContract);
        idToAddress[id] = chatContract;
    }

    function getChat(
        address _target_user,
        address _initiator_user
    ) public view returns (address) {
        bytes32 id = _getOptionId(
            _target_user,
            _initiator_user
        );
        return idToAddress[id];
    }

    function _getOptionId(
        address _target_user,
        address _initiator_user
    ) internal pure returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                _target_user,
                _initiator_user)
        );
    }
}
