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

    function depositToAave(
        address _tokenAddress,
        uint256 _amount
    )
        external
        onlyRegisteredAccount
        onlySupportedToken(_tokenAddress)
        noReentrant
    {
        if (_amount == 0) revert InvalidDepositAmount();

        IERC20 underlyingToken = IERC20(_tokenAddress);

        if (underlyingToken.balanceOf(msg.sender) < _amount)
            revert InsufficientUserBalance();

        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint8 poolIndex = getPoolIndexFromToken(_tokenAddress);

        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[poolIndex];

        uint256 leverageAmount = _amount.mul(LibFarmStorage.LEVERAGE_LEVEL);
        uint256 depositAmount = _amount + leverageAmount;

        if (pool.balanceAmount < leverageAmount)
            revert InsufficientPoolBalance();

        LibFarmStorage.Depositor storage depositor = fs.depositors[poolIndex][
            msg.sender
        ];

        address aTokenAddress = pool.aTokenAddress;

        pool.balanceAmount -= leverageAmount;
        pool.borrowAmount += leverageAmount;
        depositor.debtAmount[aTokenAddress] += leverageAmount;

        uint256 beforeATokenBalance = IERC20(aTokenAddress).balanceOf(
            address(this)
        );

        // Approve the Aave lending pool to spend the tokens
        underlyingToken.safeApprove(_lendingPool(), depositAmount);

        // Deposit tokens into Aave v2 lending pool
        ILendingPool(_lendingPool()).deposit(
            _tokenAddress,
            depositAmount,
            address(this),
            0
        );

        uint256 afterAtokenBalance = IERC20(aTokenAddress).balanceOf(
            address(this)
        );

        depositor.stakeAmount[aTokenAddress] +=
            afterAtokenBalance -
            beforeATokenBalance;
    }

    function withdrawFromAave(
        address _aTokenAddress,
        uint256 _amount
    )
        external
        onlyRegisteredAccount
        onlySupportedAToken(_aTokenAddress)
        noReentrant
    {
        uint8 poolIndex = getPoolIndexFromAToken(_aTokenAddress);

        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[poolIndex];
        LibFarmStorage.Depositor storage depositor = fs.depositors[poolIndex][
            msg.sender
        ];

        if (depositor.stakeAmount[_aTokenAddress] < _amount)
            revert InsufficientUserBalance();

        IERC20 aToken = IERC20(_aTokenAddress);

        if (aToken.balanceOf(address(this)) < _amount)
            revert InsufficientPoolBalance();

        uint256 withdrawAmount = _amount.mul(
            LibPriceOracle.getLatestPrice(LibPriceOracle.AAVE_USD_PRICE_FEED)
        );

        depositor.stakeAmount[_aTokenAddress] -= _amount;

        if (depositor.debtAmount[_aTokenAddress] < withdrawAmount)
            depositor.debtAmount[_aTokenAddress] = 0;
        else depositor.debtAmount[_aTokenAddress] -= withdrawAmount;

        depositor.repayAmount[_aTokenAddress] += withdrawAmount;

        pool.balanceAmount += withdrawAmount;
        pool.borrowAmount -= withdrawAmount;

        if (depositor.stakeAmount[_aTokenAddress] == 0) {
            uint256 rewardAmount = depositor.repayAmount[_aTokenAddress] -
                depositor.debtAmount[_aTokenAddress];

            uint256 lpReward = rewardAmount.mul(fs.interestRate).div(100);
            uint256 depositorReward = rewardAmount.sub(lpReward);

            pool.balanceAmount -= depositorReward;
            pool.borrowAmount += depositorReward;
            pool.rewardAmount += lpReward;

            depositor.rewardAmount += depositorReward;
        }

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
