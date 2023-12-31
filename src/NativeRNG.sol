// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {INativeRNG} from "./interfaces/INativeRNG.sol";
import {Types} from "./libraries/Types.sol";

// Contract to natively generate a pseudo-random number
// Required as Chainlink VRF not supported on Base

contract NativeRNG is INativeRNG {
    error NativeRNG_InvalidSeed();
    error NativeRNG_CallerIsNotRaffle();
    error NativeRNG_PrevRandomnessNotFulfilled();
    error NativeRNG_RandomnessAlreadyFulfilled();
    error NativeRNG_MinDelayNotMet();
    error NativeRNG_InvalidRandomNumber();
    error NativeRNG_InvalidCommitHash();
    error NativeRNG_AlreadyInitialised();
    error NativeRNG_ZeroAddress();
    error NativeRNG_RequestDoesNotExist();

    event RequestRandomness(uint256 indexed requestId, bytes32 indexed commitHash);

    uint256 public constant UPDATE_DELAY = 30 minutes;

    address public brrRaffle;

    uint256[] public requestIds;
    uint256 private lastRequestId;
    mapping(uint256 => Types.Request) private requests;

    uint32 public lastRandomNumber;

    constructor() {
        // Fulfill the 0 request
        requests[0] =
            Types.Request({fulfilled: true, exists: true, randomResult: 0, minUpdateTime: 0, commitHash: bytes32(0)});
        requestIds.push(0);
    }

    modifier onlyRaffle() {
        if (msg.sender != brrRaffle) revert NativeRNG_CallerIsNotRaffle();
        _;
    }

    /**
     * @notice Initializes the contract with the BRR Raffle contract address.
     * @param _brrRaffle The address of the BRR Raffle contract.
     * @dev This function can only be called once, and the provided address must not be the zero address.
     */
    function initialise(address _brrRaffle) external {
        if (brrRaffle != address(0)) revert NativeRNG_AlreadyInitialised();
        if (_brrRaffle == address(0)) revert NativeRNG_ZeroAddress();
        brrRaffle = _brrRaffle;
    }

    /**
     * @notice Requests the generation of a pseudo-random number.
     * @param _commitHash The commit hash used for generating the random number.
     * @dev Emits a RequestRandomness event upon success. Can only be called by the BRR Raffle contract.
     * Reverts if a previous request is not yet fulfilled or if the commit hash is zero.
     */
    function requestRandomness(bytes32 _commitHash) external onlyRaffle {
        if (_commitHash == bytes32(0)) revert NativeRNG_InvalidCommitHash();
        if (!requests[lastRequestId].fulfilled) revert NativeRNG_PrevRandomnessNotFulfilled();
        lastRequestId++;
        requests[lastRequestId] = Types.Request({
            fulfilled: false,
            exists: true,
            randomResult: 0,
            minUpdateTime: block.timestamp + UPDATE_DELAY,
            commitHash: _commitHash
        });
        requestIds.push(lastRequestId);
        emit RequestRandomness(lastRequestId, _commitHash);
    }

    /**
     * @notice Generates a pseudo-random number based on the provided seed.
     * @param _requestId The ID of the randomness request.
     * @param _seed The seed used to generate randomness.
     * @return The generated pseudo-random number.
     * @dev Can only be called by the BRR Raffle contract. This method is pseudo-random and should not be used
     * for true randomness. Use Chainlink VRF for true randomness. The generated number is between 1,000,000 and 1,999,999.
     * Reverts if the request does not exist, the seed is invalid, randomness is already fulfilled, or the minimum update
     * delay has not passed.
     */
    function generateRandomNumber(uint256 _requestId, string memory _seed) external onlyRaffle returns (uint32) {
        Types.Request memory request = requests[_requestId];
        if (!request.exists) revert NativeRNG_RequestDoesNotExist();
        if (request.commitHash != keccak256(abi.encode(_seed))) {
            revert NativeRNG_InvalidSeed();
        }
        if (request.fulfilled) revert NativeRNG_RandomnessAlreadyFulfilled();
        if (block.timestamp < request.minUpdateTime) revert NativeRNG_MinDelayNotMet();
        uint256 randomResult = uint256(
            keccak256(
                abi.encode(
                    _seed,
                    0,
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.prevrandao,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );
        lastRandomNumber = uint32(1000000 + (randomResult % 1000000));
        if (lastRandomNumber < 1000000 || lastRandomNumber > 1999999) {
            revert NativeRNG_InvalidRandomNumber();
        }

        requests[_requestId].fulfilled = true;
        requests[_requestId].randomResult = lastRandomNumber;

        return lastRandomNumber;
    }

    /**
     * @notice Retrieves the ID of the latest randomness request.
     * @return The ID of the latest randomness request.
     */
    function viewLatestRaffleId() external view returns (uint256) {
        return lastRequestId;
    }

    /**
     * @notice Retrieves the request details for a given request ID.
     * @param _id The ID of the request.
     * @return The details of the specified request.
     */
    function getRequest(uint256 _id) external view returns (Types.Request memory) {
        return requests[_id];
    }
}
