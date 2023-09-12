// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libraries/LibMath.sol";
import "../libraries/LibFarmStorage.sol";
import "../libraries/ReEntrancyGuard.sol";
import "../libraries/LibPriceOracle.sol";

contract BaseFacet {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using LibMath for uint256;

    event Borrow(
        address indexed _user,
        address indexed _borrowToken,
        uint256 _borrowAmount
    );

    error InvalidAccount();
    error InvalidOwner();
    error AmountZero();
    error NotSupportedToken();
    error InsufficientUserBalance();
    error InsufficientPoolBalance();
    error InsufficientBorrowBalance();
    error InsufficientCollateralBalance();
    error ZeroCollateralAmountForBorrow();
    error InvalidLiquidate();

    modifier onlyRegisteredAccount() {
        checkExistAccount(msg.sender);
        _;
    }

    modifier onlyAmountNotZero(uint256 _amount) {
        checkIfAmountNotZero(_amount);
        _;
    }

    modifier onlySupportedPool(uint8 _poolIndex) {
        checkIfSupportedPool(_poolIndex);
        _;
    }

    modifier onlySupportedToken(address _token) {
        checkIfSupportedToken(_token);
        _;
    }

    modifier onlySupportedAToken(address _token) {
        checkIfSupportedAToken(_token);
        _;
    }

    modifier onlySupportedCToken(address _token) {
        checkIfSupportedCToken(_token);
        _;
    }

    function checkExistAccount(address _sender) internal view {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        if (fs.accounts[_sender] == address(0)) revert InvalidAccount();
    }

    function checkIfAmountNotZero(uint256 _amount) internal view virtual {
        if (_amount == 0) revert AmountZero();
    }

    function checkIfSupportedPool(uint8 _poolIndex) internal view virtual {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        if (fs.pools[_poolIndex].supported == false) revert NotSupportedToken();
    }

    function checkIfSupportedToken(
        address _tokenAddress
    ) internal view virtual {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        if (
            fs.pools[0].tokenAddress != _tokenAddress ||
            fs.pools[1].tokenAddress != _tokenAddress ||
            fs.pools[2].tokenAddress != _tokenAddress
        ) revert NotSupportedToken();
    }

    function checkIfSupportedAToken(
        address _tokenAddress
    ) internal view virtual {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        if (
            fs.pools[0].aTokenAddress != _tokenAddress ||
            fs.pools[1].aTokenAddress != _tokenAddress ||
            fs.pools[2].aTokenAddress != _tokenAddress
        ) revert NotSupportedToken();
    }

    function checkIfSupportedCToken(
        address _tokenAddress
    ) internal view virtual {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        if (
            fs.pools[0].cTokenAddress != _tokenAddress ||
            fs.pools[1].cTokenAddress != _tokenAddress ||
            fs.pools[2].cTokenAddress != _tokenAddress
        ) revert NotSupportedToken();
    }

    /**
    @dev Calculates the asset amount based on the pool ID and the amount.
    @param _amount The amount to calculate the asset amount for.
    @return The calculated asset amount.
    */
    function calculateAssetAmount(
        uint8 _poolIndex,
        uint256 _amount
    ) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool memory pool = fs.pools[_poolIndex];

        uint256 totalLiquidityAmount = pool
            .borrowAmount
            .add(pool.balanceAmount)
            .add(pool.rewardAmount);

        if (pool.assetAmount == 0 || totalLiquidityAmount == 0) return _amount;

        uint256 assetAmount = _amount.mul(pool.assetAmount).div(
            totalLiquidityAmount
        );

        return assetAmount;
    }

    /**
    @dev Calculates the amount of tokens to deposit or withdraw based on the asset amount and the total liquidity of a pool by providing the pool ID.
    @param _assetAmount The amount of asset tokens the caller wants to deposit or withdraw.
    @return The amount of tokens to deposit or withdraw based on the asset amount and the total liquidity of the pool.
    @notice This function retrieves the pool data based on the pool ID and calculates the amount of tokens to deposit or withdraw based on the asset amount and the total liquidity of the pool.
    */
    function calculateAmount(
        uint8 _poolIndex,
        uint256 _assetAmount
    ) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool memory pool = fs.pools[_poolIndex];

        uint256 totalLiquidityAmount = pool
            .borrowAmount
            .add(pool.balanceAmount)
            .add(pool.rewardAmount);

        uint256 amount = _assetAmount.mul(totalLiquidityAmount).divCeil(
            pool.assetAmount
        );

        return amount;
    }

    function getUserDebt(
        address _user,
        uint8 _poolIndex
    ) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool memory pool = fs.pools[_poolIndex];
        LibFarmStorage.Depositor storage depositor = fs.depositors[_poolIndex][
            _user
        ];

        uint256 userDebt = depositor.debtAmount;

        userDebt +=
            depositor.stakeAmount[pool.cTokenAddress] *
            LibPriceOracle.getLatestPrice(pool.cTokenAddress);

        userDebt +=
            depositor.stakeAmount[pool.cTokenAddress] *
            LibPriceOracle.getLatestPrice(pool.aTokenAddress);

        return userDebt;
    }

    function getPoolIndexFromToken(
        address _token
    ) internal view returns (uint8) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        for (uint8 i; i != LibFarmStorage.MAX_POOL_LENGTH; ++i) {
            if (fs.pools[i].tokenAddress == _token) return i;
        }

        return type(uint8).max;
    }

    function getPoolIndexFromCToken(
        address _cToken
    ) internal view returns (uint8) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        for (uint8 i; i != LibFarmStorage.MAX_POOL_LENGTH; ++i) {
            if (fs.pools[i].cTokenAddress == _cToken) return i;
        }

        return type(uint8).max;
    }

    function getPoolIndexFromAToken(
        address _aToken
    ) internal view returns (uint8) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        for (uint8 i; i != LibFarmStorage.MAX_POOL_LENGTH; ++i) {
            if (fs.pools[i].aTokenAddress == _aToken) return i;
        }

        return type(uint8).max;
    }
}
