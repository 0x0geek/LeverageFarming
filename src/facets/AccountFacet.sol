// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ICompoundFacet.sol";
import "../interfaces/IAaveFacet.sol";
import "../interfaces/ICurveFacet.sol";

contract AccountFacet {
    uint256 public constant MAX_LEVERAGE = 5;
    uint256 public constant LIQUIDATION_THRESOLD = 1; // Health ratio below 1 triggers liquidation
    uint256 public constant interestRate = 10; // 10% interest rate

    address public owner;

    IERC20 usdcToken;
    IERC20 usdtToken;

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

    error AmountZero();
    error NotOnwer();

    modifier onlyOwner() {
        checkIfOwner(msg.sender);
        _;
    }

    modifier onlyAmountNotZero(uint256 _amount) {
        checkIfAmountNotZero(_amount);
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

    function checkIfAmountNotZero(uint256 _amount) internal view virtual {
        if (_amount == 0) revert AmountZero();
    }
}
