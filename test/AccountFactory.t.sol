// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./utils/HelperContract.sol";

import "../src/interfaces/IDiamondCut.sol";
import "../src/LeverageFarming.sol";
import "../src/AccountFactory.sol";

import {BaseSetup} from "./BaseSetup.sol";

contract AccountFactoryTest is BaseSetup, HelperContract {
    AccountFactory public accountFactory;

    UpgradeableBeacon public beacon;
    BeaconProxy public proxy;

    event AccountCreated(address indexed);

    function setUp() public virtual override {
        BaseSetup.setUp();
        accountFactory = new AccountFactory();

        beacon = new UpgradeableBeacon(address(accountFactory));
        proxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSignature("initialize()")
        );
    }

    function test_createAccount() public {
        vm.startPrank(alice);
        vm.expectEmit();
        emit AccountCreated(address(alice));
        accountFactory.createAccount();

        vm.expectRevert(AccountFactory.AccountAlreadyExist.selector);
        accountFactory.createAccount();

        vm.stopPrank();
    }
}
