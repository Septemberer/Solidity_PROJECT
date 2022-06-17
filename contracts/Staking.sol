// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity ^0.8.4;

contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    // Жетон награды
    IERC20Metadata public rewardToken;

    // Ставка на токен
    IERC20Metadata public stakedToken;

    // Информация о каждом пользователе, который ставит токены (stakedToken)
    mapping(address => UserInfo) public userInfo;

    // Информация об уровнях стейкинга (lvl -> [threshold, percent])
    mapping(uint256 => LevelInfo) public lvlInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 level; // Уровень пользователя
        uint256 rewardDebt; // Сколько выйгрыша выводил пользователь
        uint256 timeStart; // Время с которого считается текущий заработок
    }

    struct LevelInfo {
        uint256 threshold;
        uint256 percent;
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
        IERC20Metadata _rewardToken
    ) {
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;

        uint256 decimalsRewardToken = uint256(_rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
    }

    /**
     * @notice Высчитывает заработок юзера к данному моменту
     * @param _user: User про которого надо узнать информацию
     */
    function getRewardDebt(address _user) public view returns (uint256){
        UserInfo memory user = userInfo[_user];
        uint256 reward = (user.amount * lvlInfo[user.level].percent) * (block.timestamp - user.timeStart) / (100 * 365 * 24 * 60 * 60);
        return reward;
    }

    /**
     * @notice Возвращает структуру уровня
     * @param threshold: Ввод грани уровня
     * @param percent: Ввод процента уровня
     */
    function makeLevelInfo (uint256 threshold, uint256 percent) public view onlyOwner returns (LevelInfo memory) {
        return LevelInfo (
            threshold,
            percent
        );
    }

    function setLevelInf (LevelInfo[] memory lvls) external onlyOwner {
        lvlInfo[1] = lvls[0];
        lvlInfo[2] = lvls[1];
        lvlInfo[3] = lvls[2];
        lvlInfo[4] = lvls[3];
        lvlInfo[5] = lvls[4];
    }

    /**
     * @notice Сводная информация по пользователю
     * @param _user: Адрес интересующего пользователя
     */
    function getInfo(address _user) external view returns(UserInfo memory){
        return userInfo[_user];
    }

    /**
     * @notice Информация о полученных токенах
     * @param _user: Адрес интересующего пользователя
     */
    function getRDInfo(address _user) external view returns(uint256){
        return userInfo[_user].rewardDebt;
    }

    /**
     * @notice Информация об уровне пользователя
     * @param _user: Адрес интересующего пользователя
     */
    function getLevelInfo(address _user) external view returns(uint256){
        return userInfo[_user].level;
    }

    /**
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant{
        address _adr = _msgSender();
        UserInfo storage user = userInfo[_adr];

        if (user.amount > 0) {
            uint256 pending = getRewardDebt(_adr);
            if (pending > 0) {
                user.rewardDebt += pending;
                user.timeStart = block.timestamp;
                rewardToken.safeTransfer(
                    _adr,
                    pending
                );
            }
        } else {
            user.timeStart = block.timestamp;
        }

        if (_amount > 0) {
            user.amount = user.amount + _amount;
            user.level = getLevel(user.amount);
            stakedToken.safeTransferFrom(
                _adr,
                address(this),
                _amount
            );
        }

        emit Deposit(_adr, _amount);
    }

    /**
     * @notice Показывает уровень юзера по его вложенным средствам
     * @param amount: сколько средств
     */
    function getLevel(uint256 amount) view internal returns(uint256) {

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
