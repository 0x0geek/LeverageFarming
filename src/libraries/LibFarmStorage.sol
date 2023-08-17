// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibFarmStorage {
    bytes32 constant STORAGE_POSITION =
        keccak256("com.leveragefarming.farm.storage");

    struct Pool {
        uint256 balance;
        uint256 borrowed;
        uint256 interest;
        mapping(address => LiquidityProvider) liquidityProviders;
    }

    struct LiquidityProvider {
        uint256 amount;
    }

    struct Storage {
        bool initialized;
        mapping(uint8 => Pool) pools;
        mapping(address => bool) supportedTokens;
    }

    function farmStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
