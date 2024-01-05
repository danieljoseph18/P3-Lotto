// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Types} from "../libraries/Types.sol";

interface IRewardValidator {
    function validateTickets(address _user, uint8 _numTickets) external returns (bool);
    function setMerkleRoot(uint8 _tokenId, bytes32 _merkleRoot) external;
    function verifyWhitelisted(address _user, uint8 _tokenId, bytes32[] calldata _merkleProof)
        external
        view
        returns (bool);
    function setPrizes(uint8[] calldata _tokenIds, Types.Prize[] calldata _prizes) external;
    function addUserRewards(address _user, uint8 _tokenId) external;
}
