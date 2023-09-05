// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibFarmStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("com.leveragefarming.farm.storage");

    struct Pool {
        uint256 balanceAmount;
        uint256 interestAmount;
        uint256 borrowAmount;
        uint256 assetAmount;
        bool supported;
    }

    struct Depositor {
        uint256 assetAmount;
    }

    struct Loan {
        uint256 collateralAmount;
        uint256 borrowedAmount;
        uint256 repayAmount;
        uint256 interestAmount;
        uint256 timestamp;
    }

    struct Storage {
        bool initialized;
        mapping(address => Pool) pools;
        mapping(address => address) accounts;
        mapping(address => mapping(address => Depositor)) depositors;
        uint256 interestRate;
    }

    function farmStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
