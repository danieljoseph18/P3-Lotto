// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRNG {
    /**
     * Requests a random number from the RNG
     */
    function requestRandomWords() external returns (uint256 requestId);

    /**
     * View latest lotteryId numbers
     */
    function viewLatestRaffleId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}
