// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IAave.sol";
import "../libraries/LibFarmStorage.sol";
import "../libraries/LibOwnership.sol";
import "../libraries/LibCommonModifier.sol";

contract AaveFacet is LibCommonModifier {
    using SafeERC20 for IERC20;

    address private constant AAVE_LENDING_POOL_ADDRESSES_PROVIDER =
        0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

    error InvalidDepositAmount();
    error InsufficientBalance();

    function deposit(
        address _tokenAddress,
        uint256 _amount
    ) external onlyRegisteredAccount {
        if (_amount == 0) revert InvalidDepositAmount();

        IERC20 token = IERC20(_tokenAddress);

        if (token.balanceOf(msg.sender) < _amount) revert InsufficientBalance();

        // Transfer tokens from sender to this contract
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // Approve the Aave lending pool to spend the tokens
        token.safeApprove(_lendingPool(), _amount);

        // Deposit tokens into Aave v2 lending pool
        ILendingPool(_lendingPool()).deposit(
            _tokenAddress,
            _amount,
            address(this),
            0
        );
    }

    function withdraw(
        address _tokenAddress,
        address _aTokenAddress,
        uint256 _amount
    ) external onlyRegisteredAccount {
        IERC20 aToken = IERC20(_aTokenAddress);

        if (aToken.balanceOf(msg.sender) < _amount)
            revert InsufficientBalance();

        address lendingPoolAddr = _lendingPool();

        // Approve lending pool to spend your aTokens
        aToken.safeApprove(lendingPoolAddr, _amount);

        // Withdraw tokens from Aave v2 lending pool
        ILendingPool(lendingPoolAddr).withdraw(
            _tokenAddress,
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
