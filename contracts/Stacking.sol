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

    uint256 public DEC;

    // Жетон награды
    IERC20Metadata public rewardToken;

    // Ставка на токен
    IERC20Metadata public stakedToken;

    // enum UserLevel {
    //     NONE,
    //     TINY,
    //     SMALL,
    //     MEDIUM,
    //     BIG,
    //     HUGE
    // }

    // Информация о каждом пользователе, который ставит токены (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 level; // Уровень пользователя
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

        DEC = uint256(10 ** decimalsRewardToken);

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));

    }

    function getInfo(address _user) external view returns(UserInfo memory){
        return userInfo[_user];
    }

    function getLevel(address _user) external view returns(uint256){
        return userInfo[_user].level;
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
        } else {
            user.timeStart = block.timestamp;
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
        uint256 lvl = user.level;
        uint256 percent;

        if (lvl == 1) {
            percent = PRECISION_FACTOR * 5 / 100; // 5%
        } else if (lvl == 2) {
            percent = PRECISION_FACTOR * 7 / 100; // 7%
        } else if (lvl == 3) {
            percent = PRECISION_FACTOR * 10 / 100; // 10%
        } else if (lvl == 4) {
            percent = PRECISION_FACTOR * 15 / 100; // 15%
        } else if (lvl == 5) {
            percent = PRECISION_FACTOR * 20 / 100; // 20%
        } 
        return percent;
    }

    function setLevel(UserInfo storage user) internal {
        user.level = 0;

        if (user.amount > 0) {
            user.level = 1;
        }
        if (user.amount >= 1 * DEC) {
            // 0.1M
            user.level = 2;
        }
        if (user.amount >= 3 * DEC) {
            // 1M
            user.level = 3;
        }
        if (user.amount >= 7 * DEC) {
            // 10M
            user.level = 4;
        }
        if (user.amount >= 10 * DEC) {
            // 100M
            user.level = 5;
        }
    }

    function getRewardDebt(UserInfo storage user) internal returns (uint256){
        uint256 reward = rewardPerSek(user) * (block.timestamp - user.timeStart);
        user.timeStart = block.timestamp;
        return reward;
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
            user.rewardDebt += pending;
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
        UserInfo storage user = userInfo[msg.sender];
        rewardToken.safeTransfer(address(msg.sender), _amount);
        user.rewardDebt += _amount;
    }
}
