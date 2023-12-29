// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IRewardValidator} from "./interfaces/IRewardValidator.sol";

contract RewardValidator is IRewardValidator {
    error RewardValidator_AlreadyWhitelisted();

    struct RewardsEarned {
        uint8 tickets;
        uint16 xpEarned;
    }

    struct Prize {
        uint8 ticketReward;
        uint16 xpReward;
    }

    mapping(address _user => RewardsEarned _rewards) public userRewards;

    mapping(uint8 _tokenId => Prize _prize) public prizeForTokenId;

    mapping(address _user => mapping(uint8 _tokenId => bool _isWhitelsited)) public whitelist;

    function validateTickets(address _user, uint8 _numTickets) external returns (bool) {
        if (userRewards[_user].tickets >= _numTickets) {
            userRewards[_user].tickets -= _numTickets;
            return true;
        } else {
            return false;
        }
    }

    /// @dev Can't use a merkle tree as a result of requirement to track spending
    function addUsersToWhitelist(address[] calldata _whitelist, uint8 _tokenId) external {
        for (uint256 i = 0; i < _whitelist.length; ++i) {
            if (whitelist[_whitelist[i]][_tokenId]) {
                revert RewardValidator_AlreadyWhitelisted();
            }
            whitelist[_whitelist[i]][_tokenId] = true;
            userRewards[_whitelist[i]].tickets += prizeForTokenId[_tokenId].ticketReward;
            userRewards[_whitelist[i]].xpEarned += prizeForTokenId[_tokenId].xpReward;
        }
    }
}
