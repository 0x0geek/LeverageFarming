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

    function supplyEther(
        address payable _etherContract
    )
        external
        payable
        onlyRegisteredAccount
        onlySupportedToken(_etherContract)
        noReentrant
        returns (bool)
    {
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
        uint256 _amountToSupply
    )
        external
        onlyRegisteredAccount
        onlySupportedToken(_tokenAddress)
        noReentrant
        returns (uint)
    {
        if (_amountToSupply == 0) revert InvalidSupplyAmount();

        borrowToken(msg.sender, _tokenAddress, _amountToSupply);

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

        // Approve transfer on the ERC20 contract
        underlyingToken.safeApprove(pool.cTokenAddress, depositAmount);

        // Create a reference to the corresponding cToken contract, like cUSDC, cUSDT
        CErc20 cToken = CErc20(pool.cTokenAddress);

        LibFarmStorage.Depositor storage depositor = fs.depositors[msg.sender];
        depositor.debtAmount[poolIndex] += leverageAmount;

        uint256 balanceBeforeMint = cToken.balanceOf(address(this));

        // Mint cTokens
        uint mintResult = cToken.mint(depositAmount);

        depositor.stakeAmount[pool.cTokenAddress] +=
            cToken.balanceOf(address(this)) -
            balanceBeforeMint;

        emit TokenSupplied(mintResult, depositAmount);

        return mintResult;
    }

    function redeemCErc20Tokens(
        uint256 _amount,
        bool redeemType,
        address _cTokenAddress
    ) external onlyRegisteredAccount noReentrant returns (bool) {
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
    ) external onlyRegisteredAccount noReentrant returns (bool) {
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
