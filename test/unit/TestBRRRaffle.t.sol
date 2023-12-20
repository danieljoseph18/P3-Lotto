// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {IBRRRaffle} from "../../src/interfaces/IBRRRaffle.sol";
import {IRNG} from "../../src/interfaces/IRNG.sol";

contract TestBRRRaffle is Test {
    IBRRRaffle public raffle;
    IRNG public rng;

    function setUp() public {}
}
