// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "../interfaces/ICompoundFacet.sol";
import "../interfaces/IAaveFacet.sol";
import "../interfaces/ICurveFacet.sol";
import "../libraries/ReEntrancyGuard.sol";

import "./BaseFacet.sol";

contract AccountFacet is BaseFacet, ReEntrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using LibMath for uint256;

    address public owner;

    event Deposit(address indexed _user, uint8 _poolIndex, uint256 _amount);
    event Repay(address indexed _user, address indexed _token, uint256 _amount);
    event Withdraw(address indexed _user, uint8 _poolIndex, uint256 _amount);

    error NotOnwer();
    error ZeroAmountForWithdraw();
    error NotAvailableForWithdraw();

    modifier onlyOwner() {
        checkIfOwner(msg.sender);
        _;
    }

    function deposit(
        uint8 _poolIndex,
        uint256 _amount
    )
        external
        onlySupportedPool(_poolIndex)
        onlyAmountNotZero(_amount)
        noReentrant
    {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        LibFarmStorage.Pool storage pool = fs.pools[_poolIndex];
        address tokenAddr = pool.tokenAddress;

        if (tokenAddr == address(0)) {} else {
            if (IERC20(tokenAddr).balanceOf(msg.sender) < _amount)
                revert InsufficientUserBalance();

            IERC20(tokenAddr).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        uint256 assetAmount = calculateAssetAmount(_poolIndex, _amount);
        pool.assetAmount += assetAmount;
        pool.balanceAmount += _amount;

        LibFarmStorage.Depositor storage depositor = fs.depositors[msg.sender];

        depositor.amount[_poolIndex] += _amount;
        depositor.assetAmount[_poolIndex] += assetAmount;

        emit Deposit(msg.sender, _poolIndex, _amount);
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
        uint8 _poolIndex,
        address _token,
        uint256 _amount
    ) external onlyOwner onlySupportedToken(_token) noReentrant {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        uint8 poolIndex = getPoolIndexFromToken(_token);

        LibFarmStorage.Depositor storage depositor = fs.depositors[msg.sender];

        uint256 assetAmount = depositor.assetAmount[poolIndex];

        // check if User has sufficient withdraw amount
        if (assetAmount == 0) revert ZeroAmountForWithdraw();

        uint256 amount = calculateAmount(_poolIndex, assetAmount);

        LibFarmStorage.Pool memory pool = fs.pools[poolIndex];

        if (amount > pool.balanceAmount) revert NotAvailableForWithdraw();

        depositor.assetAmount[poolIndex] -= assetAmount;

        pool.balanceAmount -= amount;

        pool.assetAmount -= assetAmount;

        IERC20(_token).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, poolIndex, _amount);
    }

    function checkIfOwner(address _sender) internal view {
        if (owner == _sender) revert NotOnwer();
    }
}
