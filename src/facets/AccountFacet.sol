// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICompoundFacet.sol";
import "../interfaces/IAaveFacet.sol";
import "../interfaces/ICurveFacet.sol";
import "../libraries/LibCommonModifier.sol";

contract AccountFacet is LibCommonModifier {
    address public owner;

    event Deposit(
        address indexed _user,
        address indexed _token,
        uint256 _amount
    );
    event Borrow(
        address indexed _user,
        address indexed _token,
        uint256 _amount
    );
    event Repay(address indexed _user, address indexed _token, uint256 _amount);
    event Withdraw(
        address indexed _user,
        address indexed _token,
        uint256 _amount
    );

    error NotOnwer();

    modifier onlyOwner() {
        checkIfOwner(msg.sender);
        _;
    }

    function deposit(
        address token,
        uint256 amount
    ) external onlyAmountNotZero(amount) {
        emit Deposit(msg.sender, token, amount);
    }

    function borrow(
        address token,
        uint256 amount
    ) external onlyAmountNotZero(amount) {
        emit Borrow(msg.sender, token, amount);
    }

    function repay(
        address token,
        uint256 amount
    ) external onlyAmountNotZero(amount) {
        emit Repay(msg.sender, token, amount);
    }

    function withdraw(
        address token,
        uint256 amount
    ) external onlyOwner onlyAmountNotZero(amount) {
        emit Withdraw(msg.sender, token, amount);
    }

    function checkIfOwner(address _sender) internal view {
        if (owner == _sender) revert NotOnwer();
    }
}
