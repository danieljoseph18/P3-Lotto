// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {BRRRaffle} from "../src/BRRRaffle.sol";
import {NativeRNG} from "../src/NativeRNG.sol";
import {RewardValidator} from "../src/RewardValidator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployRaffle is Script {
    HelperConfig public helperConfig;

    struct Contracts {
        address usdc;
        BRRRaffle raffle;
        RewardValidator rewardValidator;
        NativeRNG rng;
        address owner;
    }

    uint64 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 deployerKey;

    function run() external returns (Contracts memory) {
        helperConfig = new HelperConfig();

        Contracts memory contracts;

        (contracts.usdc, subscriptionId, vrfCoordinator, keyHash, deployerKey) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        contracts.owner = msg.sender;
        contracts.rewardValidator = new RewardValidator();
        contracts.rng = new NativeRNG();
        contracts.raffle = new BRRRaffle(contracts.usdc, address(contracts.rng), address(contracts.rewardValidator));
        contracts.rng.initialise(address(contracts.raffle));
        contracts.raffle.setOperatorAndTreasuryAndInjectorAddresses(msg.sender, msg.sender, msg.sender);

        // transfer ownership to contracts.owner
        contracts.raffle.transferOwnership(contracts.owner);
        vm.stopBroadcast();
        return contracts;
    }
}
