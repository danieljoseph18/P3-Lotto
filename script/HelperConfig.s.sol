// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address usdc;
        uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 84531) {
            // Base Goerli
            activeNetworkConfig = getBaseTestnetNetworkConfig();
        } else if (block.chainid == 8453) {
            // Base Mainnet
            activeNetworkConfig = getBaseMainnetNetworkConfig();
        } else {
            // Anvil
            activeNetworkConfig = getDefaultNetworkConfig();
        }
    }

    function getDefaultNetworkConfig() public returns (NetworkConfig memory) {
        MockERC20 mockUsdc = new MockERC20("Mock USDC", "MUSDC", 0);
        return NetworkConfig({usdc: address(mockUsdc), deployerKey: DEFAULT_ANVIL_KEY});
    }

    function getBaseTestnetNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({usdc: 0x15DC6BB178857fD1ad54934436221211eE5d0180, deployerKey: 0x0});
    }

    function getBaseMainnetNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, deployerKey: 0x0});
    }
}
