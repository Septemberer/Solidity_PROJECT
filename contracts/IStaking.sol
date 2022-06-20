// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStaking {

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


    /**
     * @notice Высчитывает заработок юзера к данному моменту
     * @param _user: User про которого надо узнать информацию
     */
    function getRewardDebt(address _user) external view returns (uint256);

    /**
     * @notice Возвращает структуру уровня
     * @param threshold: Ввод грани уровня
     * @param percent: Ввод процента уровня
     */
    function makeLevelInfo (uint256 threshold, uint256 percent) external view returns (LevelInfo memory);


    /**
     * @notice Показывает процент юзера по его вложенным средствам
     * @param lvl: уровень
     */
    function getPercent(uint256 lvl) view external returns(uint256);


    /**
     * @notice Показывает уровень юзера по его вложенным средствам
     * @param amount: сколько средств
     */
    function getLevel(uint256 amount) view external returns(uint256);

    /**
     * @notice Устанавливает комплект уровней
     * @param lvls: массив структур уровня
     */
    function setLevelInf (LevelInfo[] memory lvls) external;

    /**
     * @notice Сводная информация по пользователю
     * @param _user: Адрес интересующего пользователя
     */
    function getInfo(address _user) external view returns(UserInfo memory);

    /**
     * @notice Информация о полученных токенах
     * @param _user: Адрес интересующего пользователя
     */
    function getRDInfo(address _user) external view returns(uint256);

    /**
     * @notice Информация об уровне пользователя
     * @param _user: Адрес интересующего пользователя
     */
    function getLevelInfo(address _user) external view returns(uint256);

    /**
     * @notice Информация о балансе пользователя
     * @param _user: Адрес интересующего пользователя
     */
    function getAmount(address _user) external view returns(uint256);

    /**
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external;


    /**
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in stakedToken)
     */
    function withdraw(uint256 _amount) external;

    /**
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external;
}
