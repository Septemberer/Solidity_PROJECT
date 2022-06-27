// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICrowdSale.sol";
import "./CrowdSale.sol";

contract CSFactory is Ownable, ReentrancyGuard {
    address public implementation;
    address[] public allCrowdSale;
    mapping(bytes32 => address) private idToAddress;

    function setImpl (address _implementation) external onlyOwner {
        implementation = _implementation;
    }

    function createCrowdSourceContract(
        IERC20Metadata _paymentToken,
        IERC20Metadata _saleToken,
        uint256 _price,
        uint256 _timePeriod,
        uint256 _poolSize,
        uint256 _percentDEX,
        address _deployer
    ) external payable returns (address crowdContract) {
        bytes32 id = _getOptionId(
            _paymentToken,
            _saleToken,
            _price,
            _timePeriod,
            _poolSize,
            _percentDEX
        );
        require(idToAddress[id] == address(0), "Crowd sourcing type exist");
        
        crowdContract = Clones.clone(implementation);
        ICrowdSale(crowdContract).initialize(
            _paymentToken,
            _saleToken,
            _price,
            _timePeriod,
            _poolSize,
            _percentDEX,
            _deployer
        );
        allCrowdSale.push(crowdContract);
        idToAddress[id] = crowdContract;
    }

    function getCrowdSale(
        IERC20Metadata _paymentToken,
        IERC20Metadata _saleToken,
        uint256 _price,
        uint256 _timePeriod,
        uint256 _poolSize,
        uint256 _percentDEX
    ) public view returns (address) {
        bytes32 id = _getOptionId(
            _paymentToken,
            _saleToken,
            _price,
            _timePeriod,
            _poolSize,
            _percentDEX
        );
        return idToAddress[id];
    }

    function _getOptionId(
        IERC20Metadata _paymentToken,
        IERC20Metadata _saleToken,
        uint256 _price,
        uint256 _timePeriod,
        uint256 _poolSize,
        uint256 _percentDEX
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _paymentToken,
                    _saleToken,
                    _price,
                    _timePeriod,
                    _poolSize,
                    _percentDEX
                )
            );
    }

    function getNumberofCloneMade() public view returns (uint256) {
        return allCrowdSale.length;
    }
}
