// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IRewardValidator} from "./interfaces/IRewardValidator.sol";

contract RewardValidator is IRewardValidator {
    mapping(address _user => uint8 _numClaimable) public userClaimableTickets;

    function validateTickets(address _user, uint8 _numTickets) external returns (bool) {
        if (userClaimableTickets[_user] >= _numTickets) {
            userClaimableTickets[_user] -= _numTickets;
            return true;
        } else {
            return false;
        }
    }

    function addClaimableTickets(address[] calldata _userList, uint8[] calldata _numTicketsList) external {
        for (uint256 i = 0; i < _userList.length; ++i) {
            userClaimableTickets[_userList[i]] += _numTicketsList[i];
        }
    }
}
