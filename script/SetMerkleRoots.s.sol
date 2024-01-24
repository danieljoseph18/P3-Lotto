// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {RewardValidator} from "../src/RewardValidator.sol";

contract SetMerkleRoots is Script {
    bytes32 constant MERKLE_ROOT_0 = 0xac0340b6da2b4bb25ef36502cc35c24c6326b8acefd42f46623ee89fabf86234;
    bytes32 constant MERKLE_ROOT_1 = 0x744aa34366baeabe37c7b6f12c7f771f06243618e5b3a505183093ba5b8b30d2;
    bytes32 constant MERKLE_ROOT_2 = 0xd116c8be622d5c29da23282f58b9b8a53fd4d4ab8d84075e29a589d258c136a4;
    bytes32 constant MERKLE_ROOT_3 = 0x47030b70f7e8bdfdee97f746e1372b2989f623cba98300413e226eeda0b92294;
    bytes32 constant MERKLE_ROOT_4 = 0xe893bc0e2ec0b2790e7218e63035370c589e780a4e5cdbe2dc5c6d0d41c27157;
    bytes32 constant MERKLE_ROOT_5 = 0x9399607caabd490959e1803c93a8a5f521671ec8e0506a41ce699614980b9067;
    bytes32 constant MERKLE_ROOT_6 = 0x0d9c34572ce086c3d936a50ffca0dbbb0a67dfc162ca37b22880f14c5daeaff2;
    bytes32 constant MERKLE_ROOT_7 = 0x6e5a14fa5a8633c52d5c0b104608a226baf10763d01c653b41dc12cae84be502;
    bytes32 constant MERKLE_ROOT_8 = 0x6e5a14fa5a8633c52d5c0b104608a226baf10763d01c653b41dc12cae84be502;
    bytes32 constant MERKLE_ROOT_9 = 0x6e5a14fa5a8633c52d5c0b104608a226baf10763d01c653b41dc12cae84be502;
    bytes32 constant MERKLE_ROOT_10 = 0xefcaef62c679d6d881e0be866e15c6b04f24a840218368fda456a26d1372e589;
    bytes32 constant MERKLE_ROOT_11 = 0xd69a0194dd17a90c6bdacf997ae5b6b3902d430a4caf71ce7d63874689b6b526;
    bytes32 constant MERKLE_ROOT_12 = 0x6e5a14fa5a8633c52d5c0b104608a226baf10763d01c653b41dc12cae84be502;
    bytes32 constant MERKLE_ROOT_13 = 0xc791c7d02f26eaa282c00cfdf955781b903a5ad846168fa2de4d333c4a019ae8;

    RewardValidator rewardValidator = RewardValidator(0x83Be5Bb7924dD075b5Cde6f1c775C9ee006d2D9B);

    function run() external {
        vm.startBroadcast();
        rewardValidator.setMerkleRoot(0, MERKLE_ROOT_0);
        rewardValidator.setMerkleRoot(1, MERKLE_ROOT_1);
        rewardValidator.setMerkleRoot(2, MERKLE_ROOT_2);
        rewardValidator.setMerkleRoot(3, MERKLE_ROOT_3);
        rewardValidator.setMerkleRoot(4, MERKLE_ROOT_4);
        rewardValidator.setMerkleRoot(5, MERKLE_ROOT_5);
        rewardValidator.setMerkleRoot(6, MERKLE_ROOT_6);
        rewardValidator.setMerkleRoot(7, MERKLE_ROOT_7);
        rewardValidator.setMerkleRoot(8, MERKLE_ROOT_8);
        rewardValidator.setMerkleRoot(9, MERKLE_ROOT_9);
        rewardValidator.setMerkleRoot(10, MERKLE_ROOT_10);
        rewardValidator.setMerkleRoot(11, MERKLE_ROOT_11);
        rewardValidator.setMerkleRoot(12, MERKLE_ROOT_12);
        rewardValidator.setMerkleRoot(13, MERKLE_ROOT_13);
        vm.stopBroadcast();
    }
}
