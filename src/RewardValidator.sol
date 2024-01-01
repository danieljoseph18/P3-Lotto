// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IRewardValidator} from "./interfaces/IRewardValidator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Types} from "./libraries/Types.sol";

contract RewardValidator is IRewardValidator, Ownable {
    error RewardValidator_AlreadyWhitelisted();
    error RewardValidator_CallerIsNotRaffle();
    error RewardValidator_PrizesNotSet();
    error RewardValidator_AlreadyInitialised();
    error RewardValidator_UnmatchedLengths();
    error RewardValidator_InvalidTokenId();

    mapping(address _user => Types.RewardsEarned _rewards) public userRewards;

    mapping(uint8 _tokenId => Types.Prize _prize) public prizeForTokenId;

    mapping(address _user => mapping(uint8 _tokenId => bool _isWhitelsited)) public whitelist;

    address public brrRaffle;
    bool private prizesSet;
    bool private isInitialised;

    constructor() Ownable(msg.sender) {}

    modifier onlyRaffle() {
        if (msg.sender != brrRaffle) revert RewardValidator_CallerIsNotRaffle();
        _;
    }

    modifier hasSetPrizes() {
        if (!prizesSet) revert RewardValidator_PrizesNotSet();
        _;
    }

    function initialise(address _brrRaffle) external onlyOwner {
        if (isInitialised) revert RewardValidator_AlreadyInitialised();
        isInitialised = true;
        brrRaffle = _brrRaffle;
        prizesSet = false;
    }

    /**
     * @notice Validates and deducts the required number of tickets from a user's balance.
     * @param _user Address of the user whose tickets are being validated.
     * @param _numTickets Number of tickets to validate.
     * @return True if the user has enough tickets; otherwise, false.
     */
    function validateTickets(address _user, uint8 _numTickets) external onlyRaffle hasSetPrizes returns (bool) {
        if (userRewards[_user].tickets >= _numTickets) {
            userRewards[_user].tickets -= _numTickets;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Adds users to the whitelist for a specific token ID and awards them their respective prizes.
     * @param _whitelist Array of addresses to whitelist.
     * @param _tokenId Token ID for which users are being whitelisted.
     * @dev Can't use a merkle tree as a result of requirement to track spending
     */
    function addUsersToWhitelist(address[] calldata _whitelist, uint8 _tokenId) external onlyOwner hasSetPrizes {
        if (_tokenId > 9) revert RewardValidator_InvalidTokenId();
        for (uint256 i = 0; i < _whitelist.length;) {
            if (whitelist[_whitelist[i]][_tokenId]) {
                revert RewardValidator_AlreadyWhitelisted();
            }
            whitelist[_whitelist[i]][_tokenId] = true;
            userRewards[_whitelist[i]].tickets += prizeForTokenId[_tokenId].ticketReward;
            userRewards[_whitelist[i]].xpEarned += prizeForTokenId[_tokenId].xpReward;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets prizes for given token IDs.
     * @param _tokenIds Array of token IDs for which prizes are being set.
     * @param _prizes Array of prizes corresponding to the token IDs.
     */
    function setPrizes(uint8[] calldata _tokenIds, Types.Prize[] calldata _prizes) external onlyOwner {
        if (_tokenIds.length != _prizes.length) revert RewardValidator_UnmatchedLengths();
        for (uint256 i = 0; i < _tokenIds.length;) {
            if (_tokenIds[i] > 9) revert RewardValidator_InvalidTokenId();
            prizeForTokenId[_tokenIds[i]] = _prizes[i];
            unchecked {
                ++i;
            }
        }
        prizesSet = true;
    }
}
