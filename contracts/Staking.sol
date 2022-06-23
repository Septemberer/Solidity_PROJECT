// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/IStaking.sol";

contract Staking is IStaking, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable rewardToken;

    IERC20Metadata public immutable stakedToken;

    // Information about each user who puts tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    // Information about stacking levels (lvl -> [threshold, percent])
    mapping(uint256 => LevelInfo) public lvlInfo;

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Create contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     */
    constructor(IERC20Metadata _stakedToken, IERC20Metadata _rewardToken) {
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;

        uint256 decimalsRewardToken = uint256(_rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
    }

    /**
     * @notice Calculates the user's earnings by this moment
     * @param _user: User about whom it is necessary to find out information
     */
    function getRewardDebt(address _user) public view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 reward = ((user.amount * lvlInfo[user.level].percent) *
            (block.timestamp - user.timeStart)) / (100 * 365 * 24 * 60 * 60);
        return reward;
    }

    /**
     * @notice Returns the level structure
     * @param threshold: Entering a level face
     * @param percent: Entering the level percentage
     */
    function makeLevelInfo(uint256 threshold, uint256 percent)
        public
        view
        onlyOwner
        returns (LevelInfo memory)
    {
        return LevelInfo(threshold, percent);
    }

    /**
     * @notice Shows the percentage of the user on his invested funds
     * @param lvl: user level
     */
    function getPercent(uint256 lvl) public view returns (uint256) {
        return lvlInfo[lvl].percent;
    }

    /**
     * @notice Shows the level of the user by his invested funds
     * @param amount: how many funds
     */
    function getLevel(uint256 amount) public view returns (uint256) {
        if (amount >= lvlInfo[5].threshold) {
            return 5;
        } else if (amount >= lvlInfo[4].threshold) {
            return 4;
        } else if (amount >= lvlInfo[3].threshold) {
            return 3;
        } else if (amount >= lvlInfo[2].threshold) {
            return 2;
        } else if (amount >= lvlInfo[1].threshold) {
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * @notice Sets a set of levels
     * @param lvls: array of level structures
     */
    function setLevelInf(LevelInfo[] memory lvls) external onlyOwner {
        for (uint8 i; i < 5; i++) {
            lvlInfo[i + 1] = lvls[i];
        }
    }

    /**
     * @notice Summary information on the user
     * @param _user: The address of the user of interest
     */
    function getInfo(address _user) external view returns (UserInfo memory) {
        return userInfo[_user];
    }

    /**
     * @notice Information about the tokens received
     * @param _user: The address of the user of interest
     */
    function getRDInfo(address _user) external view returns (uint256) {
        return userInfo[_user].rewardDebt;
    }

    /**
     * @notice User Level Information
     * @param _user: The address of the user of interest
     */
    function getLevelInfo(address _user)
        external
        view
        override
        returns (uint256)
    {
        return userInfo[_user].level;
    }

    /**
     * @notice Information about the user's balance
     * @param _user: The address of the user of interest
     */
    function getAmount(address _user) external view returns (uint256) {
        return userInfo[_user].amount;
    }

    /**
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        address _adr = _msgSender();
        UserInfo storage user = userInfo[_adr];

        if (user.amount > 0) {
            uint256 pending = getRewardDebt(_adr);
            if (pending > 0) {
                user.rewardDebt += pending;
                user.timeStart = block.timestamp;
                rewardToken.safeTransfer(_adr, pending);
            }
        } else {
            user.timeStart = block.timestamp;
        }

        if (_amount > 0) {
            user.amount = user.amount + _amount;
            user.level = getLevel(user.amount);
            stakedToken.safeTransferFrom(_adr, address(this), _amount);
        }

        emit Deposit(_adr, _amount);
    }

    /**
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in stakedToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        address _adr = _msgSender();
        UserInfo storage user = userInfo[_adr];
        require(user.amount >= _amount, "Amount to withdraw too high");

        uint256 pending = getRewardDebt(_adr);

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            user.level = getLevel(user.amount);
            stakedToken.safeTransfer(_adr, _amount);
        }

        if (pending > 0) {
            user.rewardDebt += pending;
            user.timeStart = block.timestamp;
            rewardToken.safeTransfer(_adr, pending);
        }

        emit Withdraw(_adr, _amount);
    }

    /**
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        address _adr = _msgSender();
        UserInfo storage user = userInfo[_adr];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.level = getLevel(user.amount);

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(_adr, amountToTransfer);
        }

        emit EmergencyWithdraw(_adr, amountToTransfer);
    }
}
