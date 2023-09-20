// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin-upgrade/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrade/contracts/security/ReentrancyGuardUpgradeable.sol";
import "forge-std/Test.sol";

import "./libraries/LibFarmStorage.sol";
import "./interfaces/IDiamondCut.sol";
import "./VersionAware.sol";

contract AccountFactory is
    Ownable,
    Initializable,
    ReentrancyGuardUpgradeable,
    VersionAware
{
    event AccountCreated(address indexed);
    error AccountAlreadyExist();

    function initialize() external initializer {
        versionAwareContractName = "Beacon Proxy Pattern: V1";
    }

    function createAccount() external {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        if (fs.accounts[msg.sender] == true) revert AccountAlreadyExist();

        fs.accounts[msg.sender] = true;

        emit AccountCreated(msg.sender);
    }

    function getContractNameWithVersion()
        public
        pure
        override
        returns (string memory)
    {
        return "Beacon Proxy Pattern: V1";
    }
}
