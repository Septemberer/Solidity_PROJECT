// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity ^0.8.4;

contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // Сколько wei в одном токене
    uint256 public DEC;

    // Жетон награды
    IERC20Metadata public rewardToken;

    // Ставка на токен
    IERC20Metadata public stakedToken;

    // Информация о каждом пользователе, который ставит токены (stakedToken)
    mapping(address => UserInfo) public userInfo;

    // Информация об уровнях стейкинга (lvl -> [threshold, percent])
    mapping(uint256 => uint256[2]) public lvlInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 level; // Уровень пользователя
        uint256 timeStart; // Время с которого считается текущий заработок
    }

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Create contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     */
    constructor(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _thresholdOf_1_Lvl,
        uint256 _thresholdOf_2_Lvl,
        uint256 _thresholdOf_3_Lvl,
        uint256 _thresholdOf_4_Lvl,
        uint256 _thresholdOf_5_Lvl,
        uint256 _percentFor_1_Lvl,
        uint256 _percentFor_2_Lvl,
        uint256 _percentFor_3_Lvl,
        uint256 _percentFor_4_Lvl,
        uint256 _percentFor_5_Lvl
    ) {
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        lvlInfo[0] = [0, 0];
        lvlInfo[1] = [_thresholdOf_1_Lvl, _percentFor_1_Lvl];
        lvlInfo[2] = [_thresholdOf_2_Lvl, _percentFor_2_Lvl];
        lvlInfo[3] = [_thresholdOf_3_Lvl, _percentFor_3_Lvl];
        lvlInfo[4] = [_thresholdOf_4_Lvl, _percentFor_4_Lvl];
        lvlInfo[5] = [_thresholdOf_5_Lvl, _percentFor_5_Lvl];

        uint256 decimalsRewardToken = uint256(_rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        DEC = uint256(10 ** decimalsRewardToken);

    }

    function setLevelInf (
        uint256 _thresholdOf_1_Lvl,
        uint256 _thresholdOf_2_Lvl,
        uint256 _thresholdOf_3_Lvl,
        uint256 _thresholdOf_4_Lvl,
        uint256 _thresholdOf_5_Lvl,
        uint256 _percentFor_1_Lvl,
        uint256 _percentFor_2_Lvl,
        uint256 _percentFor_3_Lvl,
        uint256 _percentFor_4_Lvl,
        uint256 _percentFor_5_Lvl
    ) external onlyOwner {
        lvlInfo[0] = [0, 0];
        lvlInfo[1] = [_thresholdOf_1_Lvl, _percentFor_1_Lvl];
        lvlInfo[2] = [_thresholdOf_2_Lvl, _percentFor_2_Lvl];
        lvlInfo[3] = [_thresholdOf_3_Lvl, _percentFor_3_Lvl];
        lvlInfo[4] = [_thresholdOf_4_Lvl, _percentFor_4_Lvl];
        lvlInfo[5] = [_thresholdOf_5_Lvl, _percentFor_5_Lvl];
    }

    /**
     * @notice Сводная информация по пользователю
     * @param _user: Адрес интересующего пользователя
     */
    function getInfo(address _user) external view returns(UserInfo memory){
        return userInfo[_user];
    }

    /**
     * @notice Информация об уровне пользователя
     * @param _user: Адрес интересующего пользователя
     */
    function getLevel(address _user) external view returns(uint256){
        return userInfo[_user].level;
    }

    /**
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];

        if (user.amount > 0) {
            uint256 pending = getRewardDebt(user);
            if (pending > 0) {
                rewardToken.safeTransfer(address(_msgSender()), pending);
            }
        } 


        if (_amount > 0) {
            user.amount = user.amount + _amount;

            setLevel(user);

            stakedToken.safeTransferFrom(
                address(_msgSender()),
                address(this),
                _amount
            );

            user.timeStart = block.timestamp;
        }

        emit Deposit(_msgSender(), _amount);
    }

    /**
     * @notice Показывает процент для заработка юзера по его уровню
     * @param user: User про которого надо узнать информацию
     */

    /**
     * @notice Задает уровень юзера по его вложенным средствам
     * @param user: User про которого надо узнать информацию
     */
    function setLevel(UserInfo storage user) internal {

        if (user.amount >= lvlInfo[5][0]) {
            user.level = 5;
        } else if (user.amount >= lvlInfo[4][0]) {
            user.level = 4;
        } else if (user.amount >= lvlInfo[3][0]) {
            user.level = 3;
        } else if (user.amount >= lvlInfo[2][0]) {
            user.level = 2;
        } else if (user.amount >= lvlInfo[1][0]) {
            user.level = 1;
        } else {
            user.level = 0;
        }

    }

    /**
     * @notice Высчитывает заработок юзера к данному моменту, обнуляет таймер
     * @param user: User про которого надо узнать информацию
     */
    function getRewardDebt(UserInfo memory user) internal view returns (uint256){
        uint256 reward = (user.amount * lvlInfo[user.level][1]) * (block.timestamp - user.timeStart) / (100 * 365 * 24 * 60 * 60);
        return reward;
    }


    /**
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in stakedToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];
        require(user.amount >= _amount, "Amount to withdraw too high");

        uint256 pending = getRewardDebt(user);

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            stakedToken.safeTransfer(address(_msgSender()), _amount);
        }

        if (pending > 0) {
            rewardToken.safeTransfer(address(_msgSender()), pending);
            user.timeStart = block.timestamp;
        }

        emit Withdraw(_msgSender(), _amount);
    }

    /**
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(_msgSender()), amountToTransfer);
        }

        emit EmergencyWithdraw(_msgSender(), amountToTransfer);
    }
}
