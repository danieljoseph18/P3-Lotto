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

    // OWNER 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
    // USER 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
    // Merkle Root: 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2
    // Proof OWNER: 0x05b26225916a54a9f7c16388731c332005e6b2f7a59dd996ab3cc9faa8357557
    // Proof USER: 0xa2b193d49eda7315164f046c1fa0491dfcaca76b5f19e62512caa4f531d71c8b
    modifier giveRewards() {
        rewardValidator.setMerkleRoot(0, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(1, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(2, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(3, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(4, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(5, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(6, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(7, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(8, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(9, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(10, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(11, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        _;
    }

    function testOnlyTokenIds0To11AreValid(uint8 _tokenId) external {
        vm.assume(_tokenId > 11);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0xa2b193d49eda7315164f046c1fa0491dfcaca76b5f19e62512caa4f531d71c8b;
        vm.prank(USER);
        vm.expectRevert();
        rewardMinter.mint(_tokenId, proof);
    }

    function testUserCantClaimARewardTwice(uint8 _tokenId) external giveRewards {
        vm.assume(_tokenId < 12);
        // claim reward for token id 1
        // claim again and expect revert
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0xa2b193d49eda7315164f046c1fa0491dfcaca76b5f19e62512caa4f531d71c8b;
        vm.startPrank(USER);
        rewardMinter.mint(_tokenId, proof);
        vm.expectRevert();
        rewardMinter.mint(_tokenId, proof);
        vm.stopPrank();
    }

    function testAUserActuallyGetsTheNFTWhenTheyClaim(uint8 _tokenId) external giveRewards {
        vm.assume(_tokenId < 12);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0xa2b193d49eda7315164f046c1fa0491dfcaca76b5f19e62512caa4f531d71c8b;
        vm.prank(USER);
        rewardMinter.mint(_tokenId, proof);

        assertEq(rewardMinter.balanceOf(USER, _tokenId), 1);
    }
}
