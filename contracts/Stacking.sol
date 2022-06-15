// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity ^0.8.4;

contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // Фактор точности
    uint256 public PRECISION_FACTOR;

    // Жетон награды
    IERC20Metadata public rewardToken;

    // Ставка на токен
    IERC20Metadata public stakedToken;

    enum UserLevel {
        NONE,
        TINY,
        SMALL,
        MEDIUM,
        BIG,
        HUGE
    }

    // Информация о каждом пользователе, который ставит токены (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        UserLevel level; // Уровень пользователя
        uint256 timeStart; // 
    }

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /*
     * @notice Create contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     */
    constructor(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken
    ) {
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;

        uint256 decimalsRewardToken = uint256(_rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));

    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            uint256 pending = getRewardDebt(user);
            if (pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount + _amount;

            setLevel(user);

            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }

        emit Deposit(msg.sender, _amount);
    }

    function percentByLevel(UserInfo memory user) internal view returns (uint256) {
        UserLevel lvl = user.level;
        uint256 percent;

        if (lvl == UserLevel.TINY) {
            percent = PRECISION_FACTOR * 5 / 100; // 5%
        } else if (lvl == UserLevel.SMALL) {
            percent = PRECISION_FACTOR * 7 / 100; // 7%
        } else if (lvl == UserLevel.MEDIUM) {
            percent = PRECISION_FACTOR * 10 / 100; // 10%
        } else if (lvl == UserLevel.BIG) {
            percent = PRECISION_FACTOR * 15 / 100; // 15%
        } else if (lvl == UserLevel.HUGE) {
            percent = PRECISION_FACTOR * 20 / 100; // 20%
        }
        return percent;
    }

    function setLevel(UserInfo memory user) internal pure{
        if (user.amount > 0) {
            user.level = UserLevel.TINY;
        } else if (user.amount > 100000) {
            // 0.1M
            user.level = UserLevel.SMALL;
        } else if (user.amount > 1000000) {
            // 1M
            user.level = UserLevel.MEDIUM;
        } else if (user.amount > 10000000) {
            // 10M
            user.level = UserLevel.BIG;
        } else if (user.amount > 100000000) {
            // 100M
            user.level = UserLevel.HUGE;
        } else {
            user.level = UserLevel.NONE;
        }
    }

    function getRewardDebt(UserInfo memory user) internal view returns (uint256){
        user.timeStart = block.timestamp;
        return rewardPerSek(user) * (block.timestamp - user.timeStart);
    }

    function rewardPerSek(UserInfo memory user) internal view returns(uint256) {
        return ((user.amount * percentByLevel(user)) / (PRECISION_FACTOR * 365 * 24 * 60 * 60));
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in stakedToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        uint256 pending = getRewardDebt(user);

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            stakedToken.safeTransfer(address(msg.sender), _amount);
        }

        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
}
