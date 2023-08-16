// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibFarmStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("com.leveragefarming.farm.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Storage {
        bool initialized;
        mapping(address => Checkpoint[]) delegatedPowerHistory;
        IERC20 bond;
    }

    function farmStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
