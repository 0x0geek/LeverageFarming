// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Facets/AccountFacet.sol";

contract AccountFactory {
    mapping(address => address) public accounts;

    constructor() {}

    function createAccount() external {
        require(
            accounts[msg.sender] == address(0),
            "AccountFactory: Account already created"
        );

        AccountFacet account = new AccountFacet();
        account.initialize(msg.sender);
        accounts[msg.sender] = address(account);
    }
}
