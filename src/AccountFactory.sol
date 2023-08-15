// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Account.sol";

contract AccountFactory {
    address internal constant PROTOCOL_ADDRESS =
        0xc00e94Cb662C3520282E6f5717214004A7f26888;

    mapping(address => address) public accounts;

    function createAccount() external {
        require(
            accounts[msg.sender] == address(0),
            "AccountFactory: Account already created"
        );

        accounts[msg.sender] = address(
            new Account(msg.sender, PROTOCOL_ADDRESS)
        );
    }
}
