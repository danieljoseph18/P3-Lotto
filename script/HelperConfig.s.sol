// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";
import {MockRNG} from "../test/mocks/MockRNG.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address usdc;
        uint64 subscriptionId;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 deployerKey;
        bool isAnvil;
    }

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 421614) {
            activeNetworkConfig = getArbTestnetNetworkConfig();
        } else if (block.chainid == 42161) {
            activeNetworkConfig = getArbMainnetNetworkConfig();
        } else {
            activeNetworkConfig = getDefaultNetworkConfig();
        }
    }

    function getDefaultNetworkConfig() public returns (NetworkConfig memory) {
        MockERC20 mockUsdc = new MockERC20("Mock USDC", "MUSDC", 0);
        return NetworkConfig({
            usdc: address(mockUsdc),
            subscriptionId: 0,
            vrfCoordinator: address(0),
            keyHash: bytes32(0),
            deployerKey: DEFAULT_ANVIL_KEY,
            isAnvil: true
        });
    }

    /// @dev Link Token: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E
    function getArbTestnetNetworkConfig() public returns (NetworkConfig memory) {
        MockERC20 mockUsdc = new MockERC20("Mock USDC", "MUSDC", 0);
        return NetworkConfig({
            usdc: address(mockUsdc),
            subscriptionId: 41,
            vrfCoordinator: 0x50d47e4142598E3411aA864e08a44284e471AC6f,
            keyHash: 0x027f94ff1465b3525f9fc03e9ff7d6d2c0953482246dd6ae07570c45d6631414,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            isAnvil: false
        });
    }

    /// @dev Link Token: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4
    function getArbMainnetNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            subscriptionId: 143,
            vrfCoordinator: 0x41034678D6C633D8a95c75e1138A360a28bA15d1,
            keyHash: 0x68d24f9a037a649944964c2a1ebd0b2918f4a243d2a99701cc22b548cf2daff0,
            deployerKey: vm.envUint("PRIVATE_KEY"),
            isAnvil: false
        });
    }
}
