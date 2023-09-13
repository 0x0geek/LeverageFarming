// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "../interfaces/ICompound.sol";
import "../libraries/LibFarmStorage.sol";
import "../libraries/LibOwnership.sol";
import "./BaseFacet.sol";

contract CompoundFacet is BaseFacet, ReEntrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event EtherSupplied(uint _mintResult, uint256 _amount);
    event TokenSupplied(uint _mintResult, uint256 _amount);
    event RedeemFinished(uint256 _redeemResult, uint256 _amount);

    error InvalidSupplyAmount();
    error InsufficientBalance();

    function supplyToken(
        address _tokenAddress,
        uint256 _amountToSupply
    )
        external
        onlyRegisteredAccount
        onlySupportedToken(_tokenAddress)
        noReentrant
        returns (uint)
    {
        if (_amountToSupply == 0) revert InvalidSupplyAmount();

        IERC20 underlyingToken = IERC20(_tokenAddress);

        if (underlyingToken.balanceOf(msg.sender) < _amountToSupply)
            revert InsufficientUserBalance();

        uint8 poolIndex = getPoolIndexFromToken(_tokenAddress);

        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[poolIndex];

        uint256 leverageAmount = _amountToSupply.mul(
            LibFarmStorage.LEVERAGE_LEVEL
        );

        if (pool.balanceAmount < leverageAmount)
            revert InsufficientPoolBalance();

        uint256 depositAmount = _amountToSupply + leverageAmount;
        // Transfer tokens from sender to this contract
        underlyingToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amountToSupply
        );

        LibFarmStorage.Depositor storage depositor = fs.depositors[poolIndex][
            msg.sender
        ];

        address cTokenAddress = pool.cTokenAddress;

        depositor.debtAmount[cTokenAddress] += leverageAmount;
        pool.borrowAmount += leverageAmount;
        pool.balanceAmount -= leverageAmount;

        // Approve transfer on the ERC20 contract
        underlyingToken.safeApprove(cTokenAddress, depositAmount);

        // Create a reference to the corresponding cToken contract, like cUSDC, cUSDT
        CErc20 cToken = CErc20(cTokenAddress);

        uint256 balanceBeforeMint = cToken.balanceOf(address(this));

        // Mint cTokens
        uint mintResult = cToken.mint(depositAmount);

        depositor.stakeAmount[cTokenAddress] +=
            cToken.balanceOf(address(this)) -
            balanceBeforeMint;

        emit TokenSupplied(mintResult, depositAmount);

        return mintResult;
    }

    function redeemCErc20Tokens(
        uint256 _amount,
        bool redeemType,
        address _cTokenAddress
    )
        external
        onlyRegisteredAccount
        onlySupportedCToken(_cTokenAddress)
        noReentrant
        returns (bool)
    {
        uint8 poolIndex = getPoolIndexFromCToken(_cTokenAddress);

        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[poolIndex];
        LibFarmStorage.Depositor storage depositor = fs.depositors[poolIndex][
            msg.sender
        ];

        if (depositor.stakeAmount[_cTokenAddress] < _amount)
            revert InsufficientUserBalance();

        // Create a reference to the corresponding cToken contract, like cUSDC, cUSDT
        CErc20 cToken = CErc20(_cTokenAddress);

        if (cToken.balanceOf(address(this)) < _amount)
            revert InsufficientPoolBalance();

        uint256 withdrawAmount = _amount.mul(cToken.exchangeRateCurrent());

        depositor.stakeAmount[_cTokenAddress] -= _amount;

        if (depositor.debtAmount[_cTokenAddress] < withdrawAmount)
            depositor.debtAmount[_cTokenAddress] = 0;
        else depositor.debtAmount[_cTokenAddress] -= withdrawAmount;

        depositor.repayAmount[_cTokenAddress] += withdrawAmount;

        pool.balanceAmount += withdrawAmount;
        pool.borrowAmount -= withdrawAmount;

        if (depositor.stakeAmount[_cTokenAddress] == 0) {
            uint256 rewardAmount = depositor.repayAmount[_cTokenAddress] -
                depositor.debtAmount[_cTokenAddress];

            uint256 lpReward = rewardAmount.mul(fs.interestRate).div(100);
            uint256 depositorReward = rewardAmount.sub(lpReward);

            pool.balanceAmount -= depositorReward;
            pool.borrowAmount += depositorReward;
            pool.rewardAmount += lpReward;

            depositor.rewardAmount += depositorReward;
        }

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(_amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(_amount);
        }

        emit RedeemFinished(redeemResult, _amount);

        return true;
    }
}
