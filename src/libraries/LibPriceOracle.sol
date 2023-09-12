// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library LibPriceOracle {
    address public constant ETH_USD_PRICE_FEED =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant USD_ETH_PRICE_FEED =
        0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
    address public constant AAVE_USD_PRICE_FEED =
        0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
    address public constant CRV_USD_PRICE_FEED =
        0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f;
    address public constant COMP_USD_PRICE_FEED =
        0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;

    function getLatestPrice(address _address) external view returns (uint256) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(_address);

        (, int256 latestPrice, , , ) = aggregator.latestRoundData();
        return uint256(latestPrice);
    }
}
