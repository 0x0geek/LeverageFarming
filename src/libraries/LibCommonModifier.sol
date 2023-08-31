// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibFarmStorage.sol";

contract LibCommonModifier {
    error InvalidAccount();
    error InvalidOwner();
    error AmountZero();

    modifier onlyRegisteredAccount() {
        checkExistAccount(msg.sender);
        _;
    }

    modifier onlyAmountNotZero(uint256 _amount) {
        checkIfAmountNotZero(_amount);
        _;
    }

    function checkExistAccount(address _sender) internal view {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        if (fs.accounts[_sender] == address(0)) revert InvalidAccount();
    }

    function checkIfAmountNotZero(uint256 _amount) internal view virtual {
        if (_amount == 0) revert AmountZero();
    }
}
