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
     * @notice Информация об уровне пользователя
     * @param _user: Адрес интересующего пользователя
     */
    function getLevelInfo(address _user) external view returns (uint256);
}
