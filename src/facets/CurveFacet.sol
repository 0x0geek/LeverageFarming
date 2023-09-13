// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "../interfaces/ICurve.sol";
import "../libraries/LibFarmStorage.sol";
import "../libraries/LibOwnership.sol";
import "./BaseFacet.sol";

contract CurveFacet is BaseFacet, ReEntrancyGuard {
    using SafeERC20 for IERC20;

    event Deposit(address indexed _poolAddress, uint256 _amount);
    event Withdraw(address indexed _poolAddress, uint256[3] _amounts);

    function depositToCurve(
        address _poolAddress,
        address[] calldata _tokenAddress,
        uint256[3] memory _amounts
    ) external onlyRegisteredAccount noReentrant returns (uint256) {
        for (uint256 i; i != _tokenAddress.length; ++i) {
            IERC20 token = IERC20(_tokenAddress[i]);

            if (token.balanceOf(msg.sender) < _amounts[i])
                revert InsufficientUserBalance();

            // Transfer tokens from sender to this contract
            token.safeTransferFrom(msg.sender, address(this), _amounts[i]);

            // Approve Curve pool to spend the tokens
            token.safeApprove(_poolAddress, _amounts[i]);
        }

        // Deposit tokens into Curve pool
        uint256 lpTokenAmount = ICurvePool(_poolAddress).add_liquidity(
            _amounts,
            0,
            true
        );

        emit Deposit(_poolAddress, lpTokenAmount);

        return lpTokenAmount;
    }

    function withdrawFromCurve(
        address _poolAddress,
        uint256 _lpTokenAmount,
        uint256[3] memory _minAmounts
    ) external onlyRegisteredAccount noReentrant returns (uint256[3] memory) {
        // Deposit tokens into Curve pool
        uint256[3] memory amounts = ICurvePool(_poolAddress).remove_liquidity(
            _lpTokenAmount,
            _minAmounts
        );

        emit Withdraw(_poolAddress, amounts);

        return amounts;
    }
}
