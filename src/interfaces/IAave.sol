// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

interface ILendingPool {
    function deposit(address, uint256, address, uint16) external;

    function withdraw(address, uint256, address) external;
}
