// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {BRRRaffle} from "../../src/BRRRaffle.sol";
import {INativeRNG} from "../../src/interfaces/INativeRNG.sol";
import {RewardValidator} from "../../src/RewardValidator.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {NativeRNG} from "../../src/NativeRNG.sol";

contract TestBRRRaffle is Test {
    BRRRaffle public raffle;
    INativeRNG public rng;
    RewardValidator public rewardValidator;
    MockERC20 public usdc;

    uint256 public constant LARGE_AMOUNT = 1e18;

    address public DEFAULT_ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public OWNER;

    uint32[] ticketNumbers;
    uint32[] bracketArray;
    uint256[] idArray;
    address[] addressArray;
    uint8[] numTicketList;

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        DeployRaffle.Contracts memory contracts = deployRaffle.run();
        raffle = contracts.raffle;
        rng = INativeRNG(contracts.rng);
        rewardValidator = contracts.rewardValidator;
        OWNER = contracts.owner;
        usdc = MockERC20(contracts.usdc);
    }

    ////////////////////////
    // REQUEST RANDOMNESS //
    ////////////////////////

    function testRequestRandomnessCanOnlyBeCalledWhenTheLastHasBeenFulfiled() external {
        vm.startPrank(address(raffle));
        rng.requestRandomness(keccak256(abi.encode("Random")));
        vm.expectRevert();
        rng.requestRandomness(keccak256(abi.encode("Random2")));
        vm.stopPrank();
    }

    function testRequestRandomnessCanOnlyBeCalledFromRaffle() external {
        vm.prank(OWNER);
        vm.expectRevert();
        rng.requestRandomness(keccak256(abi.encode("Random")));
    }

    function testRequestRandomnessCanOnlyBeCalledWithNonZeroCommitHash() external {
        vm.prank(address(raffle));
        vm.expectRevert();
        rng.requestRandomness(bytes32(0));
    }

    function testRequestRandomnessCanBeCalledASecondTimeAfterTheFirstHasBeenFulfiled() external {
        vm.prank(address(raffle));
        rng.requestRandomness(keccak256(abi.encode("Random")));

        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);

        vm.startPrank(address(raffle));
        rng.generateRandomNumber(1, "Random");
        rng.requestRandomness(keccak256(abi.encode("Random2")));
        vm.stopPrank();
    }

    ////////////////////////
    // FULFILL RANDOMNESS //
    ////////////////////////
}
