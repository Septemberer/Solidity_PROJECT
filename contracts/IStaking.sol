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
     * @notice Показывает процент юзера по его вложенным средствам
     * @param lvl: уровень
     */
    function getPercent(uint256 lvl) external view returns (uint256);

    /**
     * @notice Показывает уровень юзера по его вложенным средствам
     * @param amount: сколько средств
     */
    function getLevel(uint256 amount) external view returns (uint256);

    /**
     * @notice Информация о полученных токенах
     * @param _user: Адрес интересующего пользователя
     */
    function getRDInfo(address _user) external view returns (uint256);

    /**
     * @notice Информация об уровне пользователя
     * @param _user: Адрес интересующего пользователя
     */
    function getLevelInfo(address _user) external view returns (uint256);

    /**
     * @notice Информация о балансе пользователя
     * @param _user: Адрес интересующего пользователя
     */
    function getAmount(address _user) external view returns (uint256);
}
