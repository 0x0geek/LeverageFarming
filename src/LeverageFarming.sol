// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

contract LeverageFarming {
    uint256 public constant MAX_LEVERAGE = 5;
    uint256 public constant LIQUIDATION_THRESOLD = 1; // Health ratio below 1 triggers liquidation
    uint256 public constant interestRate = 10; // 10% interest rate

    mapping(address => bool) public supportedCollateralTokens;
}
