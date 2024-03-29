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

contract TestBRRRaffle is Test {
    BRRRaffle public raffle;
    INativeRNG public rng;
    RewardValidator public rewardValidator;
    RewardMinter public rewardMinter;
    MockERC20 public usdc;

    uint256 public constant LARGE_AMOUNT = 1e18;

    address public OWNER;
    address public USER = makeAddr("user");
    address public ATTACKER = makeAddr("attacker");
    address public NOOB = makeAddr("noob");

    uint32[] ticketNumbers;
    uint32[] bracketArray;
    uint256[] idArray;
    address[] addressArray;
    uint8[] numTicketList;
    address[] whitelistArray;

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        DeployRaffle.Contracts memory contracts = deployRaffle.run();
        raffle = contracts.raffle;
        rng = INativeRNG(contracts.rng);
        rewardValidator = contracts.rewardValidator;
        OWNER = contracts.owner;
        usdc = MockERC20(contracts.usdc);
        rewardMinter = contracts.rewardMinter;
    }

    // OWNER 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
    // USER 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
    // Merkle Root: 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2
    // Proof OWNER: 0x05b26225916a54a9f7c16388731c332005e6b2f7a59dd996ab3cc9faa8357557
    // Proof USER: 0xa2b193d49eda7315164f046c1fa0491dfcaca76b5f19e62512caa4f531d71c8b
    modifier startAndInjectFunds() {
        vm.startPrank(OWNER);
        raffle.startLottery(3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);
        usdc.mintTokens(LARGE_AMOUNT);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        raffle.injectFunds(1, 1000e6);

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
        rewardValidator.setMerkleRoot(12, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        rewardValidator.setMerkleRoot(13, 0xd50a69f19e3291080d50c37d6c83f1c7594d59aea9f325f696c11b7ab6b8e0d2);
        vm.stopPrank();
        vm.prank(USER);
        usdc.mintTokens(LARGE_AMOUNT);
        _;
    }

    // Test the Raffle Works as Expected
    function testStartingARaffle() public {
        vm.prank(OWNER);
        raffle.startLottery(3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);
        assertEq(raffle.currentLotteryId(), 1);
    }

    /////////////////////////
    // BUY TICKET FUNCTION //
    /////////////////////////

    function testPurchasingTicketsOnOpenLottery() public startAndInjectFunds {
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        for (uint32 i = 0; i < 6; i++) {
            ticketNumbers.push(1e6 + i);
        }
        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        (, uint32[] memory ticketNums,,) = raffle.viewUserInfoForLotteryId(USER, 1, 0, 6);
        for (uint32 i = 0; i < 6; i++) {
            assertEq(ticketNums[i], ticketNumbers[i]);
        }
    }

    /*
    `notContract` modifier works:
    Functions require double prank to spoof tx.origin and prevent revert
    */

    function testPurchasingTicketsOnClosedLotteryFails() public startAndInjectFunds {
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1e6 + 69);
        vm.expectRevert();
        raffle.buyTickets(2, ticketNumbers);
        vm.stopPrank();
    }

    function testBuyTicketsWithOutOfBoundNumbersFails() public startAndInjectFunds {
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(9.9e5);
        ticketNumbers.push(2e6);
        ticketNumbers.push(0);

        vm.expectRevert();
        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
    }

    function testBuyingTicketsAfterTheEndTimeFails() public startAndInjectFunds {
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1e6 + 1);
        vm.expectRevert();
        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
    }

    function testBuyingTicketsCorrectlyCalculatesTheBulkPrice() public startAndInjectFunds {
        // buy some tickets
        uint256 balanceBefore = usdc.balanceOf(USER);
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1e6 + 60);
        ticketNumbers.push(1e6 + 61);
        ticketNumbers.push(1e6 + 62);
        ticketNumbers.push(1e6 + 63);

        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        // check the price paid for the tickets
        uint256 pricePaid = balanceBefore - usdc.balanceOf(USER);
        // calculate the expected price to pay
        uint256 expectedPrice = (1e6 * 5 * (2000 + 1 - 5)) / 2000;
        // compare the 2
        console.log("Price Paid: ", pricePaid);
        console.log("Expected Price: ", expectedPrice);
        assertEq(pricePaid, expectedPrice);
    }

    function testBuyingTicketsFromAPreviousLotteryFails() public startAndInjectFunds {
        // complete a lottery
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        // start a new one
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);
        vm.stopPrank();
        // try to buy tickets
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1e6 + 69);
        vm.expectRevert();
        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
    }

    ///////////////////
    // CLAIM TICKETS //
    ///////////////////

    function testUsersCanClaimWinningTickets() public startAndInjectFunds {
        // buy the winning ticket
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1891376);
        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        // complete the lottery
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);
        // close the lottery and draw the winning number
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
        // claim the winning ticket
        vm.startPrank(USER, USER);
        bracketArray.push(5);
        idArray.push(0);
        uint256[] memory winningIds = idArray;
        uint32[] memory winningBrackets = bracketArray;
        uint256 balanceBefore = usdc.balanceOf(USER);
        raffle.claimTickets(1, winningIds, winningBrackets);
        vm.stopPrank();
        // check the user's final balance
        uint256 balanceAfter = usdc.balanceOf(USER);
        // calculate the expected balance
        console.log("Balance Before: ", balanceBefore);
        console.log("Balance After: ", balanceAfter);
        // won 400 usdc
        assertGt(balanceAfter, balanceBefore);
    }

    function testEnteringTheWrongBracketForTicketClaim() public startAndInjectFunds {
        // buy the winning ticket
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1e6);
        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        // complete the lottery
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);
        // close the lottery and draw the winning number
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
        // claim the winning ticket
        vm.startPrank(USER, USER);

        bracketArray.push(1);
        idArray.push(1);
        uint256[] memory winningIds = idArray;
        uint32[] memory winningBrackets = bracketArray;

        vm.expectRevert();
        raffle.claimTickets(1, winningIds, winningBrackets);
        vm.stopPrank();
    }

    function testClaimingTwiceForMultipleBracketsFails() public startAndInjectFunds {
        // buy the winning ticket
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1e6);
        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        // complete the lottery
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);
        // close the lottery and draw the winning number
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
        // claim the winning ticket
        vm.startPrank(USER, USER);
        bracketArray.push(5);
        bracketArray.push(5);
        idArray.push(1);
        idArray.push(1);
        uint256[] memory winningIds = idArray;
        uint32[] memory winningBrackets = bracketArray;

        vm.expectRevert();
        raffle.claimTickets(1, winningIds, winningBrackets);
        vm.stopPrank();
    }

    ////////////////////////
    // CLAIM FREE TICKETS //
    ////////////////////////

    function testClaimFreeTicketsRevertsFromNonWhitelistedUsers() public startAndInjectFunds {
        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1e6);
        address NOT_WHITELISTED = makeAddr("notWhitelisted");
        vm.startPrank(NOT_WHITELISTED, NOT_WHITELISTED);
        vm.expectRevert();
        raffle.claimFreeTickets(1, ticketNumbers);
        vm.stopPrank();
    }

    function testClaimFreeTicketsWorksWhenOwnerWhitelistsAddress() public startAndInjectFunds {
        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1e6);
        vm.startPrank(USER, USER);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0xa2b193d49eda7315164f046c1fa0491dfcaca76b5f19e62512caa4f531d71c8b;
        console.log(address(rewardMinter));
        rewardMinter.mint(0, proof);
        rewardMinter.mint(1, proof);
        rewardMinter.mint(2, proof);
        raffle.claimFreeTickets(1, ticketNumbers);
        vm.stopPrank();
    }

    function testFreeTicketsAreUsableInLiveLotteries() public startAndInjectFunds {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0xa2b193d49eda7315164f046c1fa0491dfcaca76b5f19e62512caa4f531d71c8b;

        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1891376);
        vm.startPrank(USER, USER);
        rewardMinter.mint(0, proof);
        rewardMinter.mint(1, proof);
        rewardMinter.mint(2, proof);
        raffle.claimFreeTickets(1, ticketNumbers);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);

        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
        // check if user won anything
        // if so, claim for that bracket

        (uint256[] memory userTicketIds,,,) = raffle.viewUserInfoForLotteryId(USER, 1, 0, 2);

        bool won1;
        uint8 won1Bracket;
        for (uint8 i = 0; i < 6; i++) {
            uint256 rewards = raffle.viewRewardsForTicketId(1, userTicketIds[0], i);
            if (rewards > 0) {
                won1 = true;
                won1Bracket = i;
                break;
            }
        }

        bool won2;
        uint8 won2Bracket;
        for (uint8 i = 0; i < 6; i++) {
            uint256 rewards = raffle.viewRewardsForTicketId(1, userTicketIds[1], i);
            if (rewards > 0) {
                won2 = true;
                won2Bracket = i;
                break;
            }
        }

        if (won1) {
            vm.startPrank(USER, USER);
            bracketArray.push(won1Bracket);
            idArray.push(userTicketIds[0]);
            uint256[] memory winningIds = idArray;
            uint32[] memory winningBrackets = bracketArray;
            raffle.claimTickets(1, winningIds, winningBrackets);
            vm.stopPrank();
        }

        if (won2) {
            vm.startPrank(USER, USER);
            bracketArray.push(won2Bracket);
            idArray.push(userTicketIds[1]);
            uint256[] memory winningIds = idArray;
            uint32[] memory winningBrackets = bracketArray;
            raffle.claimTickets(1, winningIds, winningBrackets);
            vm.stopPrank();
        }
    }

    function testClaimingFreeTicketsForClosedLotteriesFails() public startAndInjectFunds {
        addressArray.push(USER);
        numTicketList.push(2);

        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1e6);
        vm.prank(USER, USER);
        vm.expectRevert();
        raffle.claimFreeTickets(2, ticketNumbers);
    }

    function testUsersCantClaimFreeTicketsWithInvalidTicketNumbers() public startAndInjectFunds {
        addressArray.push(USER);
        numTicketList.push(2);

        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(2e6);
        vm.prank(USER, USER);
        vm.expectRevert();
        raffle.claimFreeTickets(1, ticketNumbers);
    }

    ///////////////////
    // CLOSE LOTTERY //
    ///////////////////

    function testCloseLotteryOnlyWorksFromOwnerAccount() public startAndInjectFunds {
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);
        vm.prank(USER);
        vm.expectRevert();
        raffle.closeLottery(1, keccak256(abi.encode("some string")));
    }

    function testOwnerCantCloseTheLotteryPrematurely() public startAndInjectFunds {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.closeLottery(1, keccak256(abi.encode("some string")));
    }

    function testOwnerCantCallCloseOnAPreviouslyEndedLottery() public startAndInjectFunds {
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        vm.startPrank(OWNER);
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();

        // start a new lottery
        vm.prank(OWNER);
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);

        // pass time
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);

        // try to close the previous lottery
        vm.expectRevert();
        raffle.closeLottery(1, keccak256(abi.encode("some string")));
    }

    //////////////////////////////////////////////////
    // Draw Final Number and Make Lottery Claimable //
    //////////////////////////////////////////////////

    function testDrawFinalNumberAndMakeLotteryClaimableOnlyWorksFromOwnerAccount() public startAndInjectFunds {
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);
        vm.prank(USER);
        vm.expectRevert();
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
    }

    function testDrawFinalNumberAndMakeLotteryClaimableOnlyWorksOnClosedLotteries() public startAndInjectFunds {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
    }

    function testDrawFinalNumberAndMakeLotteryClaimableWorks() public startAndInjectFunds {
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
    }

    function testDrawFinalNumberAndMakeLotteryClaimableSendsOwnerRemainingFundsIfAutoInjectionFalse() public {
        // start a new lottery
        vm.prank(OWNER);
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);

        // inject funds
        usdc.mintTokens(LARGE_AMOUNT);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        raffle.injectFunds(1, 1000e6);

        // pass time
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);

        uint256 ownerBalanceBefore = usdc.balanceOf(OWNER);
        // close the lottery
        vm.startPrank(OWNER);
        raffle.closeLottery(1, keccak256(abi.encode("some string")));
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", false);
        vm.stopPrank();

        // check the owner's balance
        uint256 ownerBalanceAfter = usdc.balanceOf(OWNER);
        console.log("Owner Balance Before: ", ownerBalanceBefore);
        console.log("Owner Balance After: ", ownerBalanceAfter);
        assertGt(ownerBalanceAfter, ownerBalanceBefore);
    }

    //////////////////
    // INJECT FUNDS //
    //////////////////

    function testOwnerCantInjectFundsToArbitraryLottery() public {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.injectFunds(2, 1000e6);
    }

    function testOwnerCantInjectMoreThanInPossession() public startAndInjectFunds {
        vm.startPrank(OWNER);
        usdc.approve(address(raffle), type(uint256).max);
        vm.expectRevert();
        raffle.injectFunds(1, LARGE_AMOUNT + 1);
        vm.stopPrank();
    }

    function testSettingTheInjectorLetsUserInjectFunds() public startAndInjectFunds {
        vm.prank(OWNER);
        raffle.setOperatorAndTreasuryAndInjectorAddresses(OWNER, OWNER, USER);
        vm.startPrank(USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        raffle.injectFunds(1, 1000e6);
        vm.stopPrank();
    }

    function testUserCantInjectFundsRegularly() public startAndInjectFunds {
        vm.startPrank(USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        vm.expectRevert();
        raffle.injectFunds(1, 1000e6);
        vm.stopPrank();
    }

    ///////////////////
    // START LOTTERY //
    ///////////////////

    function testOnlyOperatorCanStartLotteries() public {
        vm.prank(USER);
        vm.expectRevert();
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);
    }

    function testLotteryTimeCantBeLessThanMinimum() public {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.startLottery(1, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);
    }

    function testDiscountDivisorCantBeSetTooHigh() public {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.startLottery(block.timestamp + 3600, 1e6, 1, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);
    }

    function testRewardsBreakdownMustAddTo10000() public {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 4999], 2000);
    }

    function testWeirdRewardsBreakdown() public {
        vm.prank(OWNER);
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(0), 0, 0, 0, 2, 9998], 2000);
    }

    function testHighTreasuryFee() public {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 4999], 10001);
    }

    //////////////////////////
    // RECOVER WRONG TOKENS //
    //////////////////////////

    function testOwnerCantRecoverFundsDirectlyFromTheLottery() public startAndInjectFunds {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.recoverWrongTokens(address(usdc), 500e6);
    }

    function testOwnerIsAbleToRecoverRandomTokens() public startAndInjectFunds {
        vm.startPrank(OWNER);
        // create a random token
        MockERC20 randomToken = new MockERC20("RandomToken", "RT", 18);
        // give some to owner
        randomToken.mintTokens(1000e18);
        // send to raffle
        randomToken.transfer(address(raffle), 1000e18);
        // recover
        uint256 balanceBefore = randomToken.balanceOf(OWNER);
        raffle.recoverWrongTokens(address(randomToken), 500e18);
        uint256 balanceAfter = randomToken.balanceOf(OWNER);
        vm.stopPrank();
        assertEq(balanceAfter - balanceBefore, 500e18);
    }

    ///////////////////////////////////////
    // SET MIN AND MAX TICKET PRICE USDC //
    ///////////////////////////////////////

    function testOwnerCanUpdateMinAndMaxTicketPrice() public {
        vm.prank(OWNER);
        raffle.setMinAndMaxTicketPriceInUsdc(1e6, 1e9);
    }

    function testUpdatingMinAndMaxTicketPriceDuringLottery() public startAndInjectFunds {
        vm.prank(OWNER);
        raffle.setMinAndMaxTicketPriceInUsdc(1e6, 1e9);
    }

    function testWeirdMinAndMaxTicketPrice() public startAndInjectFunds {
        vm.prank(OWNER);
        vm.expectRevert();
        raffle.setMinAndMaxTicketPriceInUsdc(1, 0);
    }

    function testSettingBothPricesToZero() public startAndInjectFunds {
        vm.prank(OWNER);
        raffle.setMinAndMaxTicketPriceInUsdc(0, 0);
    }

    function testFuzzingTheTicketPrices(uint256 maxTicketPrice, uint256 minTicketPrice) public {
        vm.assume(minTicketPrice < maxTicketPrice);
        vm.prank(OWNER);
        raffle.setMinAndMaxTicketPriceInUsdc(minTicketPrice, maxTicketPrice);
    }

    function testUpdatingTicketPricesFromOthersFails() public {
        vm.prank(USER);
        vm.expectRevert();
        raffle.setMinAndMaxTicketPriceInUsdc(1e6, 1e9);
    }

    /////////////////////////////
    // SET MAX TICKETS PER BUY //
    /////////////////////////////

    function testFuzzingMaxTicketsPerBuy(uint256 maxTicketsPerBuy) public {
        vm.assume(maxTicketsPerBuy > 0);
        vm.prank(OWNER);
        raffle.setMaxNumberTicketsPerBuy(maxTicketsPerBuy);
    }

    function testCallingMaxTicketsPerBuyFromOthersFails() public {
        vm.prank(USER);
        vm.expectRevert();
        raffle.setMaxNumberTicketsPerBuy(1);
    }

    //////////////////////////////////////////////////////
    // SET OPERATOR AND TREASURY AND INJECTOR ADDRESSES //
    //////////////////////////////////////////////////////

    function testOnlyOwnerCanSetOperatorAndTreasuryAndInjectorAddresses() public {
        vm.prank(USER);
        vm.expectRevert();
        raffle.setOperatorAndTreasuryAndInjectorAddresses(OWNER, OWNER, OWNER);
    }

    function testFuzzingOperatorAndTreasuryAndInjectorAddresses(address operator, address treasury, address injector)
        public
    {
        vm.assume(operator != address(0));
        vm.assume(treasury != address(0));
        vm.assume(injector != address(0));
        vm.prank(OWNER);
        raffle.setOperatorAndTreasuryAndInjectorAddresses(operator, treasury, injector);
    }

    ////////////////////////////////////////////
    // CALCULATE TOTAL PRICE FOR BULK TICKETS //
    ////////////////////////////////////////////

    function testFuzzingCalculateTotalPriceForBulkTickets(
        uint256 discountDivisor,
        uint256 priceTicket,
        uint256 numberTickets
    ) public {
        uint256 boundedDiscountDivisor = bound(discountDivisor, raffle.MIN_DISCOUNT_DIVISOR(), 10000);
        uint256 boundedPrice = bound(priceTicket, raffle.minPriceTicketInUsdc(), raffle.maxPriceTicketInUsdc());
        uint256 boundedNumberTickets = bound(numberTickets, 1, raffle.maxNumberTicketsPerBuyOrClaim());
        uint256 totalPrice =
            raffle.calculateTotalPriceForBulkTickets(boundedDiscountDivisor, boundedPrice, boundedNumberTickets);
        assertEq(
            totalPrice,
            boundedPrice * boundedNumberTickets * (boundedDiscountDivisor + 1 - boundedNumberTickets)
                / boundedDiscountDivisor
        );
    }

    /////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function testViewCurrentLotteryIdIncrementsCorrectly() public startAndInjectFunds {
        assertEq(raffle.currentLotteryId(), 1);
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        vm.startPrank(OWNER);
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        raffle.startLottery(block.timestamp + 3600, 1e6, 2000, [uint256(200), 300, 500, 1500, 2500, 5000], 2000);
        vm.stopPrank();
        assertEq(raffle.currentLotteryId(), 2);
    }

    function testViewLottery() public startAndInjectFunds {
        BRRRaffle.Lottery memory lotto = raffle.viewLottery(1);
        assertEq(lotto.startTime, 1);
        assertEq(lotto.endTime, 1 + 3599);
        assertEq(lotto.priceTicketInUsdc, 1e6);
        assertEq(lotto.discountDivisor, 2000);
        assertEq(lotto.treasuryFee, 2000);
    }

    function testViewLotteryUpdatesFinalNumberOnDraw() public startAndInjectFunds {
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.number + 1);
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
        BRRRaffle.Lottery memory lotto = raffle.viewLottery(1);
        assertNotEq(lotto.finalNumber, 0);
    }

    function testViewNumbersAndStatusesForTicketIds() public startAndInjectFunds {
        // buy some tickets
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1e6 + 69);
        ticketNumbers.push(1e6 + 60);
        ticketNumbers.push(1e6 + 61);
        ticketNumbers.push(1e6 + 62);
        ticketNumbers.push(1e6 + 63);

        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        // check the numbers and statuses
        (, uint32[] memory ticketNums, bool[] memory ticketStatuses,) = raffle.viewUserInfoForLotteryId(USER, 1, 0, 5);
        for (uint32 i = 0; i < 5; i++) {
            assertEq(ticketNums[i], ticketNumbers[i]);
            assertEq(ticketStatuses[i], false);
        }
    }

    function testViewRewardsForTicketId() public startAndInjectFunds {
        // buy some tickets
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1891376);

        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        // complete the lottery
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);
        // close the lottery and draw the winning number
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
        // claim the winning ticket
        vm.startPrank(USER, USER);
        bracketArray.push(5);
        idArray.push(0);
        uint256[] memory winningIds = idArray;
        uint32[] memory winningBrackets = bracketArray;
        raffle.claimTickets(1, winningIds, winningBrackets);
        vm.stopPrank();
        // check the rewards
        uint256 rewards = raffle.viewRewardsForTicketId(1, 0, 5);
        assertGt(rewards, 0);
    }

    function testViewUserInfoForLotteryId() public startAndInjectFunds {
        // buy some tickets
        vm.startPrank(USER, USER);
        usdc.approve(address(raffle), LARGE_AMOUNT);
        ticketNumbers.push(1891376);

        raffle.buyTickets(1, ticketNumbers);
        vm.stopPrank();
        // complete the lottery
        vm.warp(block.timestamp + 1 days);
        vm.roll(block.timestamp + 1);
        // close the lottery and draw the winning number
        vm.startPrank(OWNER);
        bytes32 commitHash = keccak256(abi.encode("some string"));
        raffle.closeLottery(1, commitHash);
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        raffle.drawFinalNumberAndMakeLotteryClaimable(1, "some string", true);
        vm.stopPrank();
        // claim the winning ticket
        vm.startPrank(USER, USER);
        bracketArray.push(5);
        idArray.push(0);
        uint256[] memory winningIds = idArray;
        uint32[] memory winningBrackets = bracketArray;
        raffle.claimTickets(1, winningIds, winningBrackets);
        vm.stopPrank();
        // check the user info
        (uint256[] memory ticketIds, uint32[] memory ticketNums, bool[] memory ticketStatuses,) =
            raffle.viewUserInfoForLotteryId(USER, 1, 0, 5);
        console.log(ticketIds[0]);
        console.log(ticketNums[0]);
        console.log(ticketStatuses[0]);
    }
}
