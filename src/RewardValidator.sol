// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IRewardValidator} from "./interfaces/IRewardValidator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Types} from "./libraries/Types.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RewardValidator is IRewardValidator, Ownable {
    mapping(address => Types.RewardsEarned) public userRewards;
    mapping(uint8 => Types.Prize) public prizeForTokenId;
    mapping(uint8 => bytes32) public merkleRoots; // Merkle roots for each token ID

    uint256 private constant MAX_TOKEN_ID = 12;

    address public brrRaffle;
    address public rewardMinter;
    bool private prizesSet;
    bool private isInitialised;

    constructor() Ownable(msg.sender) {}

    modifier onlyRaffle() {
        require(msg.sender == brrRaffle, "RV: Caller is not Raffle");
        _;
    }

    modifier hasSetPrizes() {
        require(prizesSet, "RV: Prizes not set");
        _;
    }

    modifier onlyRewardMinter() {
        require(msg.sender == rewardMinter, "RV: Caller is not Reward Minter");
        _;
    }

    function initialise(address _brrRaffle, address _rewardMinter) external onlyOwner {
        require(!isInitialised, "RV: Already Initialised");
        isInitialised = true;
        brrRaffle = _brrRaffle;
        rewardMinter = _rewardMinter;
        prizesSet = false;
    }

    function validateTickets(address _user, uint8 _numTickets) external onlyRaffle hasSetPrizes returns (bool) {
        if (userRewards[_user].tickets >= _numTickets) {
            userRewards[_user].tickets -= _numTickets;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Sets the Merkle root for a specific token ID.
     * @param _tokenId The token ID.
     * @param _merkleRoot The Merkle root for the whitelist of the token ID.
     */
    function setMerkleRoot(uint8 _tokenId, bytes32 _merkleRoot) external onlyOwner {
        merkleRoots[_tokenId] = _merkleRoot;
    }

    /**
     * @notice Verifies if an address is part of the Merkle Tree whitelist for a specific token ID.
     * @param _user The user address.
     * @param _tokenId The token ID.
     * @param _merkleProof Merkle proof to verify inclusion in the whitelist.
     */
    function verifyWhitelisted(address _user, uint8 _tokenId, bytes32[] calldata _merkleProof)
        external
        view
        returns (bool)
    {
        require(_tokenId <= MAX_TOKEN_ID, "RV: Invalid Token ID");
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_merkleProof, merkleRoots[_tokenId], leaf);
    }

    function setPrizes(uint8[] calldata _tokenIds, Types.Prize[] calldata _prizes) external onlyOwner {
        require(_tokenIds.length == _prizes.length, "RV: Invalid Array Lengths");
        require(_tokenIds.length == MAX_TOKEN_ID + 1, "RV: Invalid Array Lengths");
        for (uint256 i = 0; i < _tokenIds.length;) {
            require(_tokenIds[i] <= MAX_TOKEN_ID, "RV: Invalid Token ID");
            prizeForTokenId[_tokenIds[i]] = _prizes[i];
            unchecked {
                ++i;
            }
        }
        prizesSet = true;
    }

    function addUserRewards(address _user, uint8 _tokenId) external onlyRewardMinter {
        require(_tokenId <= MAX_TOKEN_ID, "RV: Invalid Token ID");
        require(_user != address(0), "RV: Zero Address");
        Types.Prize memory prize = prizeForTokenId[_tokenId];
        userRewards[_user].tickets += prize.ticketReward;
        userRewards[_user].xpEarned += prize.xpReward;
    }
}
