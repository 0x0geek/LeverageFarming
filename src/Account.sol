// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin-upgrade/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrade/contracts/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/ILeverageFarming.sol";
import "./VersionAware.sol";

contract Account is Initializable, ReentrancyGuardUpgradeable, VersionAware {
    address public owner;
    ILeverageFarming leverageFarming;

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
    event Repay(address indexed _user, address indexed _token, uint256 amount);
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

    function initialize(
        address _owner,
        ILeverageFarming _leverage
    ) external initializer {
        owner = _owner;
        leverageFarming = _leverage;
        versionAwareContractName = "Beacon Proxy Pattern: V1";
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

    function getContractNameWithVersion()
        public
        pure
        override
        returns (string memory)
    {
        return "Beacon Proxy Pattern: V1";
    }

    function checkIfOwner(address _sender) internal view {
        if (owner == _sender) revert NotOnwer();
    }

    function checkIfAmountNotZero(uint256 _amount) internal view virtual {
        if (_amount == 0) revert AmountZero();
    }
}
