// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICompound.sol";
import "../libraries/LibFarmStorage.sol";
import "../libraries/LibOwnership.sol";

contract CompoundFacet {
    using SafeERC20 for IERC20;

    event EtherSupplied(uint _mintResult, uint256 _amount);
    event TokenSupplied(uint _mintResult, uint256 _amount);
    event RedeemFinished(uint256 _redeemResult, uint256 _amount);

    error InvalidSupplyAmount();
    error InsufficientBalance();

    function supplyEther(
        address payable _etherContract
    ) external payable returns (bool) {
        if (msg.value == 0) revert InvalidSupplyAmount();
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_etherContract);

        // cToken.mint{value: msg.value, gas: 250000}();
        cToken.mint{value: msg.value}();

        emit EtherSupplied(0, msg.value);

        return true;
    }

    function supplyToken(
        address _tokenAddress,
        address _cTokenAddress,
        uint256 _amountToSupply
    ) external returns (uint) {
        if (_amountToSupply == 0) revert InvalidSupplyAmount();

        // Create a reference to the underlying asset contract, like USDC, USDT.
        IERC20 underlying = IERC20(_tokenAddress);

        if (underlying.balanceOf(msg.sender) < _amountToSupply)
            revert InsufficientBalance();

        // Transfer tokens from sender to this contract
        underlying.safeTransferFrom(msg.sender, address(this), _amountToSupply);

        // Approve transfer on the ERC20 contract
        underlying.safeApprove(_cTokenAddress, _amountToSupply);

        // Create a reference to the corresponding cToken contract, like cUSDC, cUSDT
        CErc20 cToken = CErc20(_cTokenAddress);

        // Mint cTokens
        uint mintResult = cToken.mint(_amountToSupply);

        emit TokenSupplied(mintResult, _amountToSupply);

        return mintResult;
    }

    function redeemCErc20Tokens(
        uint256 _amount,
        bool redeemType,
        address _cTokenAddress
    ) external returns (bool) {
        // Create a reference to the corresponding cToken contract, like cUSDC, cUSDT
        CErc20 cToken = CErc20(_cTokenAddress);

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

    function redeemCEth(
        uint256 _amount,
        bool _redeemType,
        address _cEtherAddress
    ) external returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherAddress);

        uint256 redeemResult;

        if (_redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(_amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(_amount);
        }

        emit RedeemFinished(redeemResult, _amount);

        return true;
    }

    // This is needed to receive ETH when calling `redeemCEth`
    receive() external payable {}
}
