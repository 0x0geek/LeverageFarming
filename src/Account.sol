// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./interfaces/ILeverageFarming.sol";

contract Account {
    address public owner;
    ILeverageFarming leverageFarming;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Borrow(address indexed user, address indexed token, uint256 amount);
    event Repay(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Account: Only owner can call this function"
        );
        _;
    }

    constructor(address _owner, ILeverageFarming _leverage) {
        owner = _owner;
        leverageFarming = _leverage;
    }

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Account: Amount must be greater than zero");
    }

    function borrow(address token, uint256 amount) external {
        require(amount > 0, "Account: Amount must be greater than zero");
        emit Borrow(msg.sender, token, amount);
    }

    function repay(address token, uint256 amount) external {
        require(amount > 0, "Account: Amount must be greater than zero");
        emit Repay(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Account: Amount must be greater than zero");
        emit Withdraw(msg.sender, token, amount);
    }
}
