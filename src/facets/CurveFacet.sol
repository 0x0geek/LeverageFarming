// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICurve.sol";
import "../libraries/LibFarmStorage.sol";
import "../libraries/LibOwnership.sol";

contract CurveFacet {
    using SafeERC20 for IERC20;

    address internal constant CURVE_MINTER_ADDR =
        0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address internal constant CURVE_TOKEN_ADDR =
        0xD533a949740bb3306d119CC777fa900bA034cd52;

    ILiquidityGauge public crvLiquidityGauge;
    IERC20 private immutable crvToken;
    ICurveMinter private immutable crvMinter;

    event Deposit(address indexed _poolAddress, uint256 _amount);
    event Withdraw(address indexed _poolAddress, uint256[3] _amounts);
    error InsufficientBalance();

    constructor() {
        crvMinter = ICurveMinter(CURVE_MINTER_ADDR);
        crvToken = IERC20(CURVE_TOKEN_ADDR);
    }

    function deposit(
        address _poolAddress,
        address[] calldata _tokenAddress,
        uint256[3] memory _amounts
    ) external returns (uint256) {
        for (uint256 i; i != _tokenAddress.length; ++i) {
            IERC20 token = IERC20(_tokenAddress[i]);

            if (token.balanceOf(msg.sender) < _amounts[i])
                revert InsufficientBalance();

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

    function withdraw(
        address _poolAddress,
        uint256 _lpTokenAmount,
        uint256[3] memory _minAmounts
    ) external returns (uint256[3] memory) {
        // Deposit tokens into Curve pool
        uint256[3] memory amounts = ICurvePool(_poolAddress).remove_liquidity(
            _lpTokenAmount,
            _minAmounts
        );

        emit Withdraw(_poolAddress, amounts);

        return amounts;
    }
}
