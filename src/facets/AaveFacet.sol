// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "../interfaces/IAaveFacet.sol";
import "../libraries/LibFarmStorage.sol";
import "../libraries/LibOwnership.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AaveFacet {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
}
