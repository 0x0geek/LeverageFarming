// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libraries/LibMath.sol";
import "../libraries/LibFarmStorage.sol";

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

    AggregatorV3Interface internal constant ethUsdPriceFeed =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    AggregatorV3Interface internal constant usdcEthPriceFeed =
        AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    AggregatorV3Interface internal constant aaveUsdPriceFeed =
        AggregatorV3Interface(0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);
    AggregatorV3Interface internal constant curveUsdPriceFeed =
        AggregatorV3Interface(0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f);
    AggregatorV3Interface internal constant compoundPriceFeed =
        AggregatorV3Interface(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5);

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

    function borrowToken(
        address _user,
        address _borrowToken,
        uint256 _borrowAmount
    ) internal {
        uint256 userCollateralPrice = calculateTotalCollateralPrice(_user);

        if (_borrowAmount > userCollateralPrice)
            revert InsufficientCollateralBalance();

        if (IERC20(_borrowToken).balanceOf(address(this)) < _borrowAmount)
            revert InsufficientBorrowBalance();

        uint8 poolIndex = getPoolIndexFromToken(_borrowToken);

        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage poolForBorrow = fs.pools[poolIndex];
        LibFarmStorage.Depositor storage depositor = fs.depositors[_user];

        depositor.assetAmount[poolIndex] -= calculateAssetAmount(
            poolIndex,
            _borrowAmount
        );
        poolForBorrow.balanceAmount -= _borrowAmount;
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

        uint256 totalLiquidityAmount = pool.borrowAmount.add(
            pool.balanceAmount
        );

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

        uint256 totalLiquidityAmount = pool.borrowAmount.add(
            pool.balanceAmount
        );

        uint256 amount = _assetAmount.mul(totalLiquidityAmount).divCeil(
            pool.assetAmount
        );

        return amount;
    }

    /**
    @dev Returns the total liquidity of a pool by providing the pool ID.
    @return The total liquidity of the pool.
    @notice This function retrieves the pool data based on the pool ID and calculates the total liquidity of the pool by adding the total borrow amount and the current amount and subtracting the total reserve amount.
    */
    function getTotalLiquidity(
        uint8 _poolIndex
    ) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool memory pool = fs.pools[_poolIndex];

        return pool.borrowAmount.add(pool.balanceAmount);
    }

    function calculateTotalCollateralPrice(
        address _user
    ) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Depositor storage depositor = fs.depositors[_user];

        uint256 totalPrice = depositor
            .amount[1]
            .add(
                depositor
                    .amount[0]
                    .mul(LibFarmStorage.USDC_DECIMAL)
                    .div(getUsdcEthPrice())
                    .div(100)
            )
            .add(depositor.amount[2]);

        return totalPrice;
    }

    function getPoolIndexFromToken(
        address _token
    ) internal view returns (uint8) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        for (uint8 i; i != LibFarmStorage.MAX_POOL_LENGTH; ++i) {
            if (fs.pools[i].tokenAddress == _token) return i;
        }
    }

    /**
    @dev Returns the current USDC/ETH price from the Chainlink price feed.
    @return The current USDC/ETH price with 18 decimal places.
    @notice This function retrieves the latest round data from the Chainlink price feed for the USDC/ETH pair and returns the price with 18 decimal places.
            According to the documentation, the return value is a fixed point number with 18 decimals for ETH data feeds
    */
    function getUsdcEthPrice() internal view returns (uint256) {
        (, int256 answer, , , ) = usdcEthPriceFeed.latestRoundData();
        // Convert the USDC/ETH price to a decimal value with 18 decimal places
        return uint256(answer);
    }

    function getEthUsdPrice() internal view returns (uint256) {
        (, int256 answer, , , ) = ethUsdPriceFeed.latestRoundData();
        return uint256(answer);
    }

    function getTotalDebtAmount(address _user) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Depositor storage depositor = fs.depositors[_user];
        uint256 totalDebt = depositor
            .debtAmount[0]
            .mul(getEthUsdPrice())
            .add(depositor.debtAmount[1])
            .add(depositor.debtAmount[2]);
        return totalDebt;
    }
}
