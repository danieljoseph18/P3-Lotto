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

    function initialise(address _brrRaffle) external {
        if (brrRaffle != address(0)) revert NativeRNG_AlreadyInitialised();
        if (_brrRaffle == address(0)) revert NativeRNG_ZeroAddress();
        brrRaffle = _brrRaffle;
    }

    // Create a Request for a Random Number
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

    /// @dev Number is Pseudo-Random -> For True Randomness Consider Chainlink VRF
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

    function viewLatestRaffleId() external view returns (uint256) {
        return lastRequestId;
    }

    function getRequest(uint256 _id) external view returns (Types.Request memory) {
        return requests[_id];
    }
}
