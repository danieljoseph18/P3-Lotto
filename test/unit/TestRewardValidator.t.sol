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
import {Types} from "../../src/libraries/Types.sol";

contract TestRewardValidator is Test {
    BRRRaffle public raffle;
    INativeRNG public rng;
    RewardValidator public rewardValidator;
    RewardMinter public rewardMinter;
    MockERC20 public usdc;

    uint256 public constant LARGE_AMOUNT = 1e18;

    address public DEFAULT_ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public OWNER;
    address public USER = makeAddr("user");

    uint32[] ticketNumbers;
    uint32[] bracketArray;
    uint256[] idArray;
    address[] addressArray;
    uint8[] tokenIdArray;

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        DeployRaffle.Contracts memory contracts = deployRaffle.run();
        raffle = contracts.raffle;
        rng = INativeRNG(contracts.rng);
        rewardValidator = contracts.rewardValidator;
        rewardMinter = contracts.rewardMinter;
        OWNER = contracts.owner;
        usdc = MockERC20(contracts.usdc);
    }

    function testPrizesAreSetCorrectly() external {
        for (uint8 i = 0; i < 10; ++i) {
            (uint8 ticketReward, uint16 xpReward) = rewardValidator.prizeForTokenId(i);
            assertEq(ticketReward, 1);
            assertEq(xpReward, 500);
        }
    }
}
