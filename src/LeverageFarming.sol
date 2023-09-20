// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "./libraries/LibFarmStorage.sol";
import "./interfaces/IAccountFactory.sol";

contract LeverageFarming is Ownable, ReentrancyGuard {
    IAccountFactory public accountFactory;

    constructor() {
        addPool(
            0,
            LibFarmStorage.ETHER_ADDRESS,
            LibFarmStorage.CETHER_ADDRESS,
            LibFarmStorage.AETHER_ADDRESS
        ); // Ether pool

        addPool(
            1,
            LibFarmStorage.USDC_ADDRESS,
            LibFarmStorage.CUSDC_ADDRESS,
            LibFarmStorage.AUSDC_ADDRESS
        ); // USDC pool

        addPool(
            2,
            LibFarmStorage.USDT_ADDRESS,
            LibFarmStorage.CUSDT_ADDRESS,
            LibFarmStorage.AUSDT_ADDRESS
        ); // USDT pool
    }

    function setInterestRate(uint8 _interestRate) external onlyOwner {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        fs.interestRate = _interestRate;
    }

    function getInterestRate() external view returns (uint8) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        return fs.interestRate;
    }

    function setSupportedToken(
        uint8 _poolIndex,
        bool _supported
    ) external onlyOwner {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[_poolIndex];
        if (pool.supported != _supported) pool.supported = _supported;
    }

    function isSupportedToken(uint8 _poolIndex) external view returns (bool) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[_poolIndex];
        return pool.supported;
    }

    function addPool(
        uint8 _poolIndex,
        address _token,
        address _cToken,
        address _aToken
    ) internal {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        fs.pools[_poolIndex] = LibFarmStorage.Pool({
            tokenAddress: _token,
            cTokenAddress: _cToken,
            aTokenAddress: _aToken,
            balanceAmount: 0,
            interestAmount: 0,
            borrowAmount: 0,
            assetAmount: 0,
            rewardAmount: 0,
            supported: true
        });
    }
}
