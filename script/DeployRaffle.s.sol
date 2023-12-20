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
    BRRRaffle public raffle;
    RNG public rng;
    MockRNG public mockRng;
    RewardValidator public rewardValidator;

    address usdc;
    uint64 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 deployerKey;
    bool isMainnet;

    function run() public {
        helperConfig = new HelperConfig();
        (usdc, subscriptionId, vrfCoordinator, keyHash, deployerKey, isMainnet) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        vm.stopBroadcast();
    }
}
