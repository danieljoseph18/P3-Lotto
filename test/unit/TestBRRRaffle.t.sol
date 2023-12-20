// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {BRRRaffle} from "../../src/BRRRaffle.sol";
import {IRNG} from "../../src/interfaces/IRNG.sol";
import {RewardValidator} from "../../src/RewardValidator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestBRRRaffle is Test {
    BRRRaffle public raffle;
    IRNG public rng;
    RewardValidator public rewardValidator;
    IERC20 public usdc;

    address public OWNER;

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        DeployRaffle.Contracts memory contracts = deployRaffle.run();
        raffle = contracts.raffle;
        rng = IRNG(contracts.rng);
        rewardValidator = contracts.rewardValidator;
        OWNER = contracts.owner;
        usdc = IERC20(contracts.usdc);
    }

    function testDeployment() public view {
        console.log("Raffle: ", address(raffle));
        console.log("RNG: ", address(rng));
        console.log("RewardValidator: ", address(rewardValidator));
    }
}
