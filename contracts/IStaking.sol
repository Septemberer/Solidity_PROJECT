// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStaking {
    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 level; // User Level
        uint256 rewardDebt; // How much winnings did the user withdraw
        uint256 timeStart; // The time from which the current earnings are calculated
    }

    struct LevelInfo {
        uint256 threshold;
        uint256 percent;
    }

    /**
     * @notice User Level Information
     * @param _user: The address of the user of interest
     */
    function getLevelInfo(address _user) external view returns (uint256);
}
