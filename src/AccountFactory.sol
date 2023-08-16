// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Account.sol";
import "./interfaces/ILeverageFarming.sol";

contract AccountFactory {
    address internal constant PROTOCOL_ADDRESS =
        0xc00e94Cb662C3520282E6f5717214004A7f26888;

    mapping(address => address) public accounts;

    function createAccount() external {
        require(
            accounts[msg.sender] == address(0),
            "AccountFactory: Account already created"
        );

        Account account = new Account();
        account.initialize(msg.sender, ILeverageFarming(PROTOCOL_ADDRESS));
        accounts[msg.sender] = address(account);
    }
}
