// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IRewardValidator {
    function validateTickets(address _user, uint8 _numTickets) external returns (bool);
    function addUsersToWhitelist(address[] calldata _whitelist, uint8 _tokenId) external;
    function whitelist(address _user, uint8 _tokenId) external returns (bool);
    function userRewards(address _user) external returns (uint8 tickets, uint16 xpEarned);
    function prizeForTokenId(uint8 _tokenId) external returns (uint8 ticketReward, uint16 xpReward);
}
