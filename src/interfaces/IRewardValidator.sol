// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRewardValidator {
    function userClaimableTickets(address _user) external view returns (uint8);
    function validateTickets(address _user, uint8 _numTickets) external returns (bool);
    function addClaimableTickets(address[] calldata _userList, uint8[] calldata _numTicketsList) external;
}
