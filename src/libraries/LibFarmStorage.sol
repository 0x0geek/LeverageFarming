// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibFarmStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("com.leveragefarming.farm.storage");

    struct Pool {
        uint256 balance;
        uint256 interest;
    }

    struct Depositor {
        uint256 amount;
    }

    struct Storage {
        bool initialized;
        mapping(uint8 => Pool) pools;
        mapping(address => bool) supportedTokens;
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
