// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {BRRRaffle} from "../../src/BRRRaffle.sol";
import {INativeRNG} from "../../src/interfaces/INativeRNG.sol";
import {RewardValidator} from "../../src/RewardValidator.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {NativeRNG} from "../../src/NativeRNG.sol";
import {RewardMinter} from "../../src/RewardMinter.sol";

contract TestRewardMinter is Test {
// BRRRaffle public raffle;
// INativeRNG public rng;
// RewardValidator public rewardValidator;
// RewardMinter public rewardMinter;
// MockERC20 public usdc;

// uint256 public constant LARGE_AMOUNT = 1e18;

// address public DEFAULT_ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
// address public OWNER;
// address public USER = makeAddr("user");

// uint32[] ticketNumbers;
// uint32[] bracketArray;
// uint256[] idArray;
// address[] addressArray;
// uint8[] tokenIdArray;

// function setUp() public {
//     DeployRaffle deployRaffle = new DeployRaffle();
//     DeployRaffle.Contracts memory contracts = deployRaffle.run();
//     raffle = contracts.raffle;
//     rng = INativeRNG(contracts.rng);
//     rewardValidator = contracts.rewardValidator;
//     rewardMinter = contracts.rewardMinter;
//     OWNER = contracts.owner;
//     usdc = MockERC20(contracts.usdc);
// }

// modifier giveRewards() {
//     addressArray.push(USER);
//     addressArray.push(OWNER);
//     rewardValidator.addUsersToWhitelist(addressArray, 0);
//     rewardValidator.addUsersToWhitelist(addressArray, 1);
//     rewardValidator.addUsersToWhitelist(addressArray, 2);
//     rewardValidator.addUsersToWhitelist(addressArray, 3);
//     rewardValidator.addUsersToWhitelist(addressArray, 4);
//     rewardValidator.addUsersToWhitelist(addressArray, 5);
//     rewardValidator.addUsersToWhitelist(addressArray, 6);
//     rewardValidator.addUsersToWhitelist(addressArray, 7);
//     rewardValidator.addUsersToWhitelist(addressArray, 8);
//     rewardValidator.addUsersToWhitelist(addressArray, 9);
//     _;
// }

// function testOnlyTokenIds0To9AreValid(uint8 _tokenId) external {
//     vm.assume(_tokenId > 9);
//     vm.prank(USER);
//     vm.expectRevert();
//     rewardMinter.mint(_tokenId);
// }

// function testUserCantClaimARewardTwice(uint8 _tokenId) external giveRewards {
//     vm.assume(_tokenId < 10);
//     // claim reward for token id 1
//     // claim again and expect revert
//     vm.startPrank(USER);
//     rewardMinter.mint(_tokenId);
//     vm.expectRevert();
//     rewardMinter.mint(_tokenId);
//     vm.stopPrank();
// }

// function testAUserActuallyGetsTheNFTWhenTheyClaim(uint8 _tokenId) external giveRewards {
//     vm.assume(_tokenId < 10);
//     vm.prank(USER);
//     rewardMinter.mint(_tokenId);

//     assertEq(rewardMinter.balanceOf(USER, _tokenId), 1);
// }
}
