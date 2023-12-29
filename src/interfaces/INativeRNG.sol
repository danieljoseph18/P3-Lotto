// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Types} from "../libraries/Types.sol";

interface INativeRNG {
    function requestRandomness(bytes32 _commitHash) external;
    function generateRandomNumber(uint256 _requestId, string memory _seed) external returns (uint32);
    function viewLatestRaffleId() external view returns (uint256);
    function getRequest(uint256 _requestId) external view returns (Types.Request memory);
}
