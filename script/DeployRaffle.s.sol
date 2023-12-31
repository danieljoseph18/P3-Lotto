// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {BRRRaffle} from "../src/BRRRaffle.sol";
import {NativeRNG} from "../src/NativeRNG.sol";
import {RewardValidator} from "../src/RewardValidator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Types} from "../src/libraries/Types.sol";

contract DeployRaffle is Script {
    HelperConfig public helperConfig;

    struct Contracts {
        address usdc;
        BRRRaffle raffle;
        RewardValidator rewardValidator;
        NativeRNG rng;
        address owner;
    }

    uint8[] private tokenIdArray;
    Types.Prize[] private prizeArray;
    uint256 deployerKey;

    function run() external returns (Contracts memory) {
        helperConfig = new HelperConfig();

        Contracts memory contracts;

        (contracts.usdc, deployerKey) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        contracts.owner = msg.sender;
        contracts.rng = new NativeRNG();
        contracts.rewardValidator = new RewardValidator();
        contracts.raffle = new BRRRaffle(contracts.usdc, address(contracts.rng), address(contracts.rewardValidator));
        contracts.rng.initialise(address(contracts.raffle));
        contracts.raffle.setOperatorAndTreasuryAndInjectorAddresses(msg.sender, msg.sender, msg.sender);
        contracts.rewardValidator.initialise(address(contracts.raffle));

        // set prizes for each token ID
        tokenIdArray = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        for (uint8 i = 0; i < tokenIdArray.length; i++) {
            prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 500}));
        }
        contracts.rewardValidator.setPrizes(tokenIdArray, prizeArray);
        // transfer ownership to contracts.owner
        contracts.raffle.transferOwnership(contracts.owner);
        contracts.rewardValidator.transferOwnership(contracts.owner);
        contracts.rng.transferOwnership(contracts.owner);
        vm.stopBroadcast();
        return contracts;
    }
}
