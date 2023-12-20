// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {BRRRaffle} from "../src/BRRRaffle.sol";
import {RNG} from "../src/RNG.sol";
import {MockRNG} from "../test/mocks/MockRNG.sol";
import {RewardValidator} from "../src/RewardValidator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * struct NetworkConfig {
 *         address usdc;
 *         uint64 subscriptionId;
 *         address vrfCoordinator;
 *         bytes32 keyHash;
 *         uint256 deployerKey;
 *     }
 */

contract DeployRaffle is Script {
    HelperConfig public helperConfig;

    struct Contracts {
        address usdc;
        BRRRaffle raffle;
        RewardValidator rewardValidator;
        address rng; // address to generalize
        address owner;
    }

    uint64 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 deployerKey;
    bool isAnvil;

    function run() external returns (Contracts memory) {
        helperConfig = new HelperConfig();

        Contracts memory contracts;

        (contracts.usdc, subscriptionId, vrfCoordinator, keyHash, deployerKey, isAnvil) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        contracts.owner = msg.sender;
        contracts.rewardValidator = new RewardValidator();
        if (isAnvil) {
            contracts.rng = address(new MockRNG());
        } else {
            contracts.rng = address(new RNG(subscriptionId, vrfCoordinator, keyHash));
        }
        contracts.raffle = new BRRRaffle(contracts.usdc, contracts.rng, address(contracts.rewardValidator));

        vm.stopBroadcast();
        return contracts;
    }
}
