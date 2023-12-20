// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRNG} from "../../src/interfaces/IRNG.sol";
import {IBRRRaffle} from "../../src/interfaces/IBRRRaffle.sol";

contract MockRNG is IRNG, Ownable {
    address public brrRaffle;
    uint32 public randomResult;
    uint256 public nextRandomResult;
    uint256 public latestRaffleId;

    mapping(uint256 => bool) public requestFulfilled;
    uint256 public lastRequestId;

    error MockRNG_PermissionDenied();
    error MockRNG_AlreadyFulfilled();

    /**
     * @notice Constructor
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Set the address for the brrRaffle
     * @param _brrRaffle: address of the BRR raffle
     */
    function setRaffleAddress(address _brrRaffle) external onlyOwner {
        brrRaffle = _brrRaffle;
    }

    /**
     * @notice Set the next random result
     * @param _nextRandomResult: next random result
     */
    function setNextRandomResult(uint256 _nextRandomResult) external onlyOwner {
        nextRandomResult = _nextRandomResult;
    }

    /**
     * @notice Request randomness
     * @dev This is a mock function to mimic requesting randomness
     */
    function requestRandomWords() external override returns (uint256 requestId) {
        if (msg.sender != brrRaffle) revert MockRNG_PermissionDenied();
        lastRequestId = lastRequestId + 1; // Increment request ID for each call
        requestId = lastRequestId;
        requestFulfilled[requestId] = false;
        fulfillRandomWords(requestId, nextRandomResult); // Directly call the fulfillment function
    }

    /**
     * @notice View latestRaffleId
     */
    function viewLatestRaffleId() external view override returns (uint256) {
        return latestRaffleId;
    }

    /**
     * @notice View random result
     */
    function viewRandomResult() external view override returns (uint32) {
        return randomResult;
    }

    /**
     * @notice Mock function to fulfill random words
     * @param _requestId: request ID
     * @param _randomness: mock randomness
     */
    function fulfillRandomWords(uint256 _requestId, uint256 _randomness) internal {
        if (requestFulfilled[_requestId]) revert MockRNG_AlreadyFulfilled();
        randomResult = uint32(1000000 + (_randomness % 1000000));
        requestFulfilled[_requestId] = true;
        latestRaffleId = IBRRRaffle(brrRaffle).viewCurrentLotteryId();
    }
}
