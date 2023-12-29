// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library Types {
    struct Request {
        bool fulfilled;
        bool exists;
        uint32 randomResult;
        uint256 minUpdateTime;
        bytes32 commitHash;
    }
}
