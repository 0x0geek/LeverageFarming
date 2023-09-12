// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "../interfaces/IAave.sol";
import "../libraries/LibOwnership.sol";
import "./BaseFacet.sol";

contract AaveFacet is BaseFacet, ReEntrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private constant AAVE_LENDING_POOL_ADDRESSES_PROVIDER =
        0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

    error InvalidDepositAmount();
    error InsufficientBalance();

    function depositToAave(
        address _tokenAddress,
        uint256 _amount
    )
        external
        onlySupportedToken(_tokenAddress)
        onlyRegisteredAccount
        noReentrant
    {
        if (_amount == 0) revert InvalidDepositAmount();

        borrowToken(msg.sender, _tokenAddress, _amount);

        IERC20 token = IERC20(_tokenAddress);

        uint8 poolIndex = getPoolIndexFromToken(_tokenAddress);

        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[poolIndex];

        uint256 leverageAmount = _amount.mul(LibFarmStorage.LEVERAGE_LEVEL);
        uint256 depositAmount = _amount + leverageAmount;

        if (pool.balanceAmount < leverageAmount)
            revert InsufficientPoolBalance();

        pool.balanceAmount -= leverageAmount;

        LibFarmStorage.Depositor storage depositor = fs.depositors[msg.sender];
        depositor.debtAmount[poolIndex] += leverageAmount;

        uint256 beforeATokenBalance = IERC20(pool.aTokenAddress).balanceOf(
            address(this)
        );

        // Approve the Aave lending pool to spend the tokens
        token.safeApprove(_lendingPool(), depositAmount);

        // Deposit tokens into Aave v2 lending pool
        ILendingPool(_lendingPool()).deposit(
            _tokenAddress,
            depositAmount,
            address(this),
            0
        );

        uint256 afterAtokenBalance = IERC20(pool.aTokenAddress).balanceOf(
            address(this)
        );

        depositor.stakeAmount[pool.aTokenAddress] +=
            afterAtokenBalance -
            beforeATokenBalance;
    }

    function withdrawFromAave(
        address _aTokenAddress,
        uint256 _amount
    ) external onlyRegisteredAccount noReentrant {
        IERC20 aToken = IERC20(_aTokenAddress);

        if (aToken.balanceOf(msg.sender) < _amount)
            revert InsufficientBalance();

        address lendingPoolAddr = _lendingPool();

        // Approve lending pool to spend your aTokens
        aToken.safeApprove(lendingPoolAddr, _amount);

        // Withdraw tokens from Aave v2 lending pool
        ILendingPool(lendingPoolAddr).withdraw(
            _aTokenAddress,
            _amount,
            address(this)
        );
    }

    function _lendingPool() internal view returns (address) {
        return
            ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES_PROVIDER)
                .getLendingPool();
    }
}
