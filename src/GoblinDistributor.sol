// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GoblinDistributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public usdc;

    mapping(address => uint256) public rewards;

    uint32 private constant TIME_TO_CLAIM = 10 days;

    uint32 claimOpen;
    uint32 public claimEnd;

    event RewardsAdded(uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsWithdrawn(uint256 indexed amount);
    event WinnersSet(uint256 indexed timestamp);

    constructor(address _usdc) Ownable(msg.sender) {
        usdc = IERC20(_usdc);
    }

    /// @dev USDC can only be updated before claimOpen
    function updateUsdc(address _usdc) external onlyOwner {
        if (claimOpen != 0) {
            require(block.timestamp < claimOpen, "GoblinDistributor: Claiming Already Open");
        }
        usdc = IERC20(_usdc);
    }

    function setClaimOpen(uint32 _claimOpen) external onlyOwner {
        require(block.timestamp < _claimOpen, "GoblinDistributor: Invalid Timestamp");
        if (claimOpen != 0) {
            // If ClaimOpen Set, Require Claiming Not Open Already
            require(block.timestamp < claimOpen, "GoblinDistributor: Claiming Already Open");
        }
        claimOpen = _claimOpen;
        claimEnd = _claimOpen + TIME_TO_CLAIM;
    }

    function topUpFunds(uint256 _amount) external onlyOwner {
        require(_amount != 0, "GoblinDistributor: Amount is Zero");
        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        emit RewardsAdded(_amount);
    }

    function withdrawAll(address _token) external onlyOwner {
        require(block.timestamp >= claimEnd, "GoblinDistributor: Claiming Not Over");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "GoblinDistributor: No Balance");
        IERC20(_token).safeTransfer(msg.sender, balance);
        emit RewardsWithdrawn(balance);
    }

    function setWinners(address[] calldata _users, uint256[] calldata _rewardTotalUsdc) external onlyOwner {
        uint256 userLen = _users.length;
        require(userLen == _rewardTotalUsdc.length, "GoblinDistributor: Array Length Mismatch");
        require(userLen != 0, "GoblinDistributor: Size is Zero");
        if (claimOpen != 0) {
            require(block.timestamp < claimOpen, "GoblinDistributor: Claiming Already Open");
        }

        for (uint256 i = 0; i < userLen;) {
            rewards[_users[i]] = _rewardTotalUsdc[i];
            unchecked {
                i += 1;
            }
        }

        emit WinnersSet(block.timestamp);
    }

    function claimRewards() external nonReentrant {
        require(block.timestamp >= claimOpen && block.timestamp <= claimEnd, "GoblinDistributor: Claiming Not Open");
        uint256 reward = rewards[msg.sender];
        require(reward != 0, "GoblinDistributor: No Rewards");
        rewards[msg.sender] = 0;

        usdc.safeTransfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    function getPendingRewards() external view returns (uint256) {
        return rewards[msg.sender];
    }

    function isClaimingLive() external view returns (bool) {
        return block.timestamp >= claimOpen && block.timestamp <= claimEnd;
    }

    function getContractRewardBalance() public view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function getTimeToClaim() public view returns (uint256) {
        return block.timestamp < claimOpen ? claimOpen - block.timestamp : 0;
    }
}
