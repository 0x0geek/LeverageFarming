// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "../src/libraries/LibFarmStorage.sol";

import "../src/interfaces/IDiamondCut.sol";
import "../src/LeverageFarming.sol";
import "../src/AccountFactory.sol";

import {BaseSetup} from "./BaseSetup.sol";

contract LeverageFarmingTest is BaseSetup {
    LeverageFarming public farming;

    function setUp() public virtual override {
        BaseSetup.setUp();
        farming = new LeverageFarming();
    }

    function test_setInterestRate() public {
        farming.setInterestRate(85);
        assertEq(farming.getInterestRate(), 85);
    }

    function test_setSupportedToken() public {
        farming.setSupportedToken(1, false);
        assertEq(farming.isSupportedToken(1), false);
    }
}
