// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/ICompoundFacet.sol";
import "../interfaces/IAaveFacet.sol";
import "../interfaces/ICurveFacet.sol";
import "../libraries/LibCommonModifier.sol";
import "../libraries/ReEntrancyGuard.sol";
import "../libraries/LibMath.sol";

contract AccountFacet is LibCommonModifier, ReEntrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using LibMath for uint256;

    address public owner;

    event Deposit(
        address indexed _user,
        address indexed _token,
        uint256 _amount
    );
    event Borrow(
        address indexed _user,
        address indexed _token,
        uint256 _amount
    );
    event Repay(address indexed _user, address indexed _token, uint256 _amount);
    event Withdraw(
        address indexed _user,
        address indexed _token,
        uint256 _amount
    );

    error NotOnwer();
    error InsufficientBalance();
    error ZeroAmountForWithdraw();
    error NotAvailableForWithdraw();

    modifier onlyOwner() {
        checkIfOwner(msg.sender);
        _;
    }

    function deposit(
        address _token,
        uint256 _amount
    )
        external
        onlySupportedToken(_token)
        onlyAmountNotZero(_amount)
        noReentrant
    {
        if (IERC20(_token).balanceOf(msg.sender) < _amount)
            revert InsufficientBalance();

        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[_token];

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 assetAmount = calculateAssetAmount(_token, _amount);
        pool.assetAmount += assetAmount;
        pool.balanceAmount += _amount;

        LibFarmStorage.Depositor storage depositor = fs.depositors[_token][
            msg.sender
        ];

        depositor.assetAmount += assetAmount;

        emit Deposit(msg.sender, _token, _amount);
    }

    function borrow(
        address _token,
        uint256 _amount
    )
        external
        onlySupportedToken(_token)
        onlyAmountNotZero(_amount)
        noReentrant
    {
        // LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        // LibFarmStorage.Loan storage loanData = fs.loans[msg.sender];

        emit Borrow(msg.sender, _token, _amount);
    }

    function repay(
        address _token,
        uint256 _amount
    )
        external
        onlySupportedToken(_token)
        onlyAmountNotZero(_amount)
        noReentrant
    {
        emit Repay(msg.sender, _token, _amount);
    }

    function withdraw(
        address _token,
        uint256 _amount
    ) external onlyOwner onlySupportedToken(_token) noReentrant {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Depositor storage depositor = fs.depositors[_token][
            msg.sender
        ];

        uint256 assetAmount = depositor.assetAmount;

        // check if User has sufficient withdraw amount
        if (assetAmount == 0) revert ZeroAmountForWithdraw();

        uint256 amount = calculateAmount(_token, assetAmount);

        LibFarmStorage.Pool memory pool = fs.pools[_token];

        if (amount > pool.balanceAmount) revert NotAvailableForWithdraw();

        depositor.assetAmount -= assetAmount;

        pool.balanceAmount -= amount;

        pool.assetAmount -= assetAmount;

        IERC20(_token).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, _token, _amount);
    }

    /**
    @dev Calculates the asset amount based on the pool ID and the amount.
    @param _amount The amount to calculate the asset amount for.
    @return The calculated asset amount.
    */
    function calculateAssetAmount(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool memory pool = fs.pools[_token];

        uint256 liquidityAmount = getTotalLiquidity(_token);

        if (pool.assetAmount == 0 || liquidityAmount == 0) return _amount;

        uint256 assetAmount = _amount.mul(pool.assetAmount).div(
            liquidityAmount
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
        address _token,
        uint256 _assetAmount
    ) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool memory pool = fs.pools[_token];

        uint256 totalLiquidityAmount = getTotalLiquidity(_token);

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
    function getTotalLiquidity(address _token) internal view returns (uint256) {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool memory pool = fs.pools[_token];

        return pool.borrowAmount.add(pool.balanceAmount);
    }

    function checkIfOwner(address _sender) internal view {
        if (owner == _sender) revert NotOnwer();
    }
}
