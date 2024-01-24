// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {BRRRaffle} from "../src/BRRRaffle.sol";
import {NativeRNG} from "../src/NativeRNG.sol";
import {RewardValidator} from "../src/RewardValidator.sol";
import {RewardMinter} from "../src/RewardMinter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Types} from "../src/libraries/Types.sol";

contract DeployRaffle is Script {
    HelperConfig public helperConfig;

    struct Contracts {
        address usdc;
        BRRRaffle raffle;
        RewardValidator rewardValidator;
        RewardMinter rewardMinter;
        NativeRNG rng;
        address owner;
    }

    Types.Prize[] private prizeArray;

    function run() external returns (Contracts memory) {
        helperConfig = new HelperConfig();

        Contracts memory contracts;

        (contracts.usdc,) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        contracts.owner = msg.sender;
        contracts.rng = new NativeRNG();
        contracts.rewardValidator = new RewardValidator();
        contracts.rewardMinter = new RewardMinter(
            address(contracts.rewardValidator), "ipfs://QmTiFMFVxHY8hA4eQXLLTpR7SizAKGKM4uo6J36H15F4Co/"
        );
        contracts.raffle = new BRRRaffle(contracts.usdc, address(contracts.rng), address(contracts.rewardValidator));
        contracts.rng.initialise(address(contracts.raffle));
        contracts.raffle.setOperatorAndTreasuryAndInjectorAddresses(msg.sender, msg.sender, msg.sender);
        contracts.rewardValidator.initialise(address(contracts.raffle), address(contracts.rewardMinter));

        // Early Adopter
        prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 250}));
        // Launch
        prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 250}));
        // Bridge
        prizeArray.push(Types.Prize({ticketReward: 2, xpReward: 500}));
        // OG Goblin
        prizeArray.push(Types.Prize({ticketReward: 3, xpReward: 750}));
        // Level Up
        prizeArray.push(Types.Prize({ticketReward: 3, xpReward: 750}));
        // Top Trader
        prizeArray.push(Types.Prize({ticketReward: 3, xpReward: 750}));
        // Quiz Master
        prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 250}));
        // Meme Legend
        prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 250}));
        // BSCN
        prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 250}));
        // Normie Capital
        prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 250}));
        // BNS
        prizeArray.push(Types.Prize({ticketReward: 2, xpReward: 500}));
        // DAPDAP
        prizeArray.push(Types.Prize({ticketReward: 1, xpReward: 250}));
        // Seamless
        prizeArray.push(Types.Prize({ticketReward: 3, xpReward: 750}));
        // Aerodrome
        prizeArray.push(Types.Prize({ticketReward: 2, xpReward: 500}));

        contracts.rewardValidator.setPrizes(prizeArray);
        // transfer ownership to contracts.owner
        contracts.raffle.transferOwnership(contracts.owner);
        contracts.rewardValidator.transferOwnership(contracts.owner);
        contracts.rng.transferOwnership(contracts.owner);
        vm.stopBroadcast();
        return contracts;
    }
}
