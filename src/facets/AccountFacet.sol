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
        address _token,
        uint256 _amount
    ) external onlySupportedToken(_token) onlyAmountNotZero(_amount) {
        emit Deposit(msg.sender, _token, _amount);
    }

    function borrow(
        address _token,
        uint256 _amount
    ) external onlySupportedToken(_token) onlyAmountNotZero(_amount) {
        emit Borrow(msg.sender, _token, _amount);
    }

    function repay(
        address _token,
        uint256 _amount
    ) external onlySupportedToken(_token) onlyAmountNotZero(_amount) {
        emit Repay(msg.sender, _token, _amount);
    }

    function withdraw(
        address _token,
        uint256 _amount
    ) external onlyOwner onlySupportedToken(_token) onlyAmountNotZero(_amount) {
        emit Withdraw(msg.sender, _token, _amount);
    }

    function checkIfOwner(address _sender) internal view {
        if (owner == _sender) revert NotOnwer();
    }
}
