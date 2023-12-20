// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRNG {
    /**
     * @notice Request random words from ChainLink's VRF Coordinator
     */
    function requestRandomWords() external returns (uint256 requestId);

    /**
     * @notice Set the address for the brrRaffle
     * @param _brrRaffle: address of the BRR Raffle
     */
    function setRaffleAddress(address _brrRaffle) external;

    /**
     * @notice View latestRaffleId
     */
    function viewLatestRaffleId() external view returns (uint256);

    /**
     * @notice View random result
     */
    function viewRandomResult() external view returns (uint32);
}
