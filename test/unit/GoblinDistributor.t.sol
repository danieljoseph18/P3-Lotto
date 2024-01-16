// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {GoblinDistributor} from "../../src/GoblinDistributor.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract GoblinDistributorTest is Test {
    address public OWNER = makeAddr("owner");
    address public USER = makeAddr("user");

    GoblinDistributor goblin;
    ERC20Mock usdc;

    address[] winningWallets;
    uint256[] winningAmounts;

    function setUp() public {
        // Winner Whitelist
        winningWallets.push(0x9D7Df63F3E57533454E6923cb7Daf5e81D9a1AE1);
        winningWallets.push(0x919E6E6905C67bc784FcF5c510A4e58D0b2C1E4d);
        winningWallets.push(0xf20D2762203F5568f6C9263e266F61d9037F9a1D);
        winningWallets.push(0x21168cB1d9f715F14A75f4A4455bD2fb1B20d178);
        winningWallets.push(0x740DB4cFdEBd6C6CeCa9C6B662EA4034f9A7EB90);
        winningWallets.push(0x5458B50Ebc34c8e2068caf4e45454479DeD0F578);
        winningWallets.push(0x50c516Ad3B9720D2fCBDA68037050d6Ac55eAc40);
        winningWallets.push(0xc01a3B87375C0D53502f62CA2dBe4FAF2018e1e3);
        winningWallets.push(0xE2ae7a3934eB60615Cd80239b59E978f3679eA90);
        winningWallets.push(0xbfC2317E344cBA38e79378d6690069D3C547FF6f);
        winningWallets.push(0xAD2E3E120Cb529674E5fDab0f6d643B733B6667f);
        winningWallets.push(0xb0BA52ead64C94eb3EB3e37B9618530805915735);
        winningWallets.push(0xD9dAe58eE91546a7bcCBf37657130D0bF2B997f6);
        winningWallets.push(0xBCfb2333F32BCA374ad8a587e72Aa71F20c2Acb7);
        winningWallets.push(0xC4d726B9Bb2DEB3Cbc6710c721955c6357eF4A83);
        winningWallets.push(0x80f54e8Ba04D0d09AFE84DE366f56276512058ee);
        winningWallets.push(0xAa1E27305983e2C2d65902A549cf5d4690303167);
        winningWallets.push(0x2F91Ee5d5AbA4911cF34b8e17d5af71601bFccda);
        winningWallets.push(0xB58ac9e3a69ea746EE85EbD15fE14bcC61fD39D0);
        winningWallets.push(0xb0BA52ead64C94eb3EB3e37B9618530805915735);
        winningWallets.push(0x5458B50Ebc34c8e2068caf4e45454479DeD0F578);
        winningWallets.push(0xEaC6725Ed50eE60daf1f47424F63A3b935569e31);
        winningWallets.push(0x3932E2df2c603920c047D5829f4469d5E8F1E738);
        winningWallets.push(0x32CD4Ce454c1FdaeE6Be3fD8fda8E1b28968fFD9);
        winningWallets.push(0xea11DDB23Fb8c30097C7F9E4283223A5B8054357);

        // Winning Amounts
        winningAmounts.push(176460000);
        winningAmounts.push(112180000);
        winningAmounts.push(102070000);
        winningAmounts.push(132730000);
        winningAmounts.push(105000000);
        winningAmounts.push(260140000);
        winningAmounts.push(102130000);
        winningAmounts.push(126710000);
        winningAmounts.push(129370000);
        winningAmounts.push(118240000);
        winningAmounts.push(100120000);
        winningAmounts.push(251690000);
        winningAmounts.push(527830000);
        winningAmounts.push(103990000);
        winningAmounts.push(153110000);
        winningAmounts.push(101330000);
        winningAmounts.push(118380000);
        winningAmounts.push(188160000);
        winningAmounts.push(101630000);
        winningAmounts.push(251690000);
        winningAmounts.push(260140000);
        winningAmounts.push(230090000);
        winningAmounts.push(237610000);
        winningAmounts.push(215790000);
        winningAmounts.push(221880000);

        vm.startPrank(OWNER);
        usdc = new ERC20Mock();
        goblin = new GoblinDistributor(address(usdc));
        goblin.setWinners(winningWallets, winningAmounts);
        goblin.setClaimOpen(uint32(block.timestamp) + 5 minutes);
        vm.stopPrank();
    }

    modifier getCurrency() {
        vm.startPrank(OWNER);
        usdc.mint(OWNER, 1000 ether);
        usdc.mint(USER, 1000 ether);
        vm.stopPrank();
        _;
    }

    ////////////////////////
    // Top Up Funds Tests //
    ///////////////////////

    function testTopUpFundsWorksAsExpected() public getCurrency {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(5000e6);
        vm.stopPrank();
        assertEq(goblin.getContractRewardBalance(), 5000e6);
    }

    function testTopUpFundsFailsFromNonOwner() public getCurrency {
        vm.startPrank(USER);
        usdc.approve(address(goblin), 100 ether);
        vm.expectRevert();
        goblin.topUpFunds(5000e6);
        vm.stopPrank();
    }

    function testTopUpFundsWorksFromOwner() public getCurrency {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(5000e6);
        vm.stopPrank();
        assertEq(goblin.getContractRewardBalance(), 5000e6);
    }

    function testTopUpFundsFailsIfInsufficientFunds() public {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        vm.expectRevert();
        goblin.topUpFunds(5000e6);
        vm.stopPrank();
    }

    function testTopUpFundsFailsIfNoApproval() public getCurrency {
        vm.prank(OWNER);
        vm.expectRevert();
        goblin.topUpFunds(5000e6);
    }

    event RewardsAdded(uint256 indexed amount);

    function testTopUpFundsEmitsAnEventIfSuccessful() public getCurrency {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        vm.expectEmit();
        emit RewardsAdded(5000e6);
        goblin.topUpFunds(5000e6);
    }

    ////////////////////////
    // Withdraw All Tests //
    ///////////////////////

    event RewardsWithdrawn(uint256 indexed amount);

    function testWithdrawAllWorksAsExpectedFromOwner() public getCurrency {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(5000e6);
        vm.stopPrank();

        vm.warp(block.timestamp + 11 days);

        vm.prank(OWNER);
        vm.expectEmit();
        emit RewardsWithdrawn(5000e6);
        goblin.withdrawAll(address(usdc));

        assertEq(goblin.getContractRewardBalance(), 0);
    }

    function testWithdrawAllFailsFromNonOwner() public getCurrency {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(5000e6);
        vm.stopPrank();

        vm.warp(block.timestamp + 11 days);

        vm.prank(USER);
        vm.expectRevert();
        goblin.withdrawAll(address(usdc));
    }

    function testWithdrawAllFailsIfClaimingNotOver() public getCurrency {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(5000e6);
        vm.stopPrank();

        vm.prank(OWNER);
        vm.expectRevert();
        goblin.withdrawAll(address(usdc));
    }

    function testWithdrawAllFailsIfContractBalanceIsZero() public getCurrency {
        vm.warp(block.timestamp + 8 days);

        vm.prank(OWNER);
        vm.expectRevert();
        goblin.withdrawAll(address(usdc));
    }

    ///////////////////////
    // Add Winners Tests //
    ///////////////////////

    event WinnersSet(uint256 indexed timestamp);

    function testAddWinnersLetsOwnerAddWinners() public getCurrency {
        address[] memory addressArray = new address[](1);
        addressArray[0] = USER;
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = 1e8;

        vm.startPrank(OWNER);
        vm.expectEmit();
        emit WinnersSet(block.timestamp);
        goblin.setWinners(addressArray, uintArray);
        vm.stopPrank();
        assertEq(goblin.rewards(USER), 1e8);
    }

    function testAddWinnersFailsFromNonOwner() public getCurrency {
        // Have to warp past cooldown period as timestamp starts at 0

        address[] memory addressArray = new address[](1);
        addressArray[0] = USER;
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = 5000e6;

        vm.prank(USER);
        vm.expectRevert();
        goblin.setWinners(addressArray, uintArray);
    }

    function testAddWinnersWithHugeArrays() public getCurrency {
        address[] memory addressArray = new address[](100);
        for (uint256 i = 0; i < 100; i++) {
            addressArray[i] = USER;
        }
        uint256[] memory uintArray = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            uintArray[i] = 1e6;
        }

        vm.startPrank(OWNER);
        vm.expectEmit();
        emit WinnersSet(block.timestamp);
        goblin.setWinners(addressArray, uintArray);
        vm.stopPrank();
        assertEq(goblin.rewards(USER), 1e6);
    }

    function testAddWinnersWithMultipleUsers() public getCurrency {
        address[] memory addressArray = new address[](100);
        for (uint256 i = 0; i < 100; i++) {
            if (i % 2 == 0) {
                addressArray[i] = USER;
            } else {
                addressArray[i] = OWNER;
            }
        }
        uint256[] memory uintArray = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            uintArray[i] = 1e6;
        }
        vm.startPrank(OWNER);
        vm.expectEmit();
        emit WinnersSet(block.timestamp);
        goblin.setWinners(addressArray, uintArray);
        vm.stopPrank();

        assertEq(goblin.rewards(USER), 1e6);
        assertEq(goblin.rewards(OWNER), 1e6);
    }

    /////////////////////////
    // Claim Rewards Tests //
    /////////////////////////

    event RewardsClaimed(address indexed user, uint256 amount);

    modifier addRewards() {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(100 ether);
        vm.stopPrank();

        address[] memory addressArray = new address[](100);
        for (uint256 i = 0; i < 100; i++) {
            addressArray[i] = USER;
        }
        uint256[] memory uintArray = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            uintArray[i] = 1e6; // Updated to 1e6 (1 USD)
        }

        vm.startPrank(OWNER);
        goblin.setWinners(addressArray, uintArray);
        vm.stopPrank();
        assertEq(goblin.rewards(USER), 1e6);
        _;
    }

    function testClaimRewardsLetsUsersClaimRewardsTheCorrectAmountOfRewards() public getCurrency {
        address[] memory addressArray = new address[](1);
        addressArray[0] = USER;
        uint256[] memory uintArray = new uint256[](1);
        uintArray[0] = 1e8;

        vm.startPrank(OWNER);
        goblin.setWinners(addressArray, uintArray);
        vm.stopPrank();
        assertEq(goblin.rewards(USER), 1e8);

        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(100 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        vm.prank(USER);
        vm.expectEmit();
        emit RewardsClaimed(USER, 1e8);
        goblin.claimRewards();
        assertEq(usdc.balanceOf(address(goblin)), 100 ether - 1e8);
    }

    function testClaimRewardsRevertsIfClaimingPeriodNotOpen() public getCurrency addRewards {
        vm.prank(USER);
        vm.expectRevert();
        goblin.claimRewards();

        vm.warp(block.timestamp + 11 days);
        vm.prank(USER);
        vm.expectRevert();
        goblin.claimRewards();
    }

    function testClaimRewardsFailsIfRewardsAreEmpty() public getCurrency addRewards {
        vm.warp(block.timestamp + 1 days);
        vm.prank(OWNER);
        vm.expectRevert();
        goblin.claimRewards();
    }

    function testClaimRewardsFailsIfContractHasInsufficientFunds() public getCurrency {
        vm.startPrank(OWNER);
        usdc.approve(address(goblin), 100 ether);
        goblin.topUpFunds(1e5);
        vm.stopPrank();

        address[] memory addressArray = new address[](100);
        for (uint256 i = 0; i < 100; i++) {
            addressArray[i] = USER;
        }
        uint256[] memory uintArray = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            uintArray[i] = 1e6;
        }

        vm.startPrank(OWNER);
        goblin.setWinners(addressArray, uintArray);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        vm.prank(USER);
        vm.expectRevert();
        goblin.claimRewards();
    }

    function testClaimRewardsIncreasesUsersUSDCBalance() public getCurrency addRewards {
        uint256 balBefore = usdc.balanceOf(USER);
        vm.warp(block.timestamp + 1 days);
        vm.prank(USER);
        goblin.claimRewards();
        uint256 balAfter = usdc.balanceOf(USER);
        assertEq(balAfter - balBefore, 1e6);
    }
}
