// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin-upgrade/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrade/contracts/security/ReentrancyGuardUpgradeable.sol";

import "./Account.sol";
import "./libraries/LibFarmStorage.sol";
import "./interfaces/IDiamondCut.sol";
import "./VersionAware.sol";

contract AccountFactory is
    Ownable,
    Initializable,
    ReentrancyGuardUpgradeable,
    VersionAware
{
    address public protocolAddr;
    address[] public facetAddrs;

    error AccountAlreadyExist();
    error InvalidCaller();

    modifier onlyLeverageFarmingProtocol() {
        checkLeverageFarmingProtocol(msg.sender);
        _;
    }

    function initialize(address[] memory _facetAddrs) external initializer {
        versionAwareContractName = "Beacon Proxy Pattern: V1";
        facetAddrs = _facetAddrs;
    }

    function setFacetAddrs(
        address[] memory _facetAddrs
    ) external onlyLeverageFarmingProtocol {
        facetAddrs = _facetAddrs;
    }

    function setProtocolAddr(address _protocolAddr) external onlyOwner {
        protocolAddr = _protocolAddr;
    }

    function createAccount() external {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();

        if (fs.accounts[msg.sender] == true) revert AccountAlreadyExist();

        fs.accounts[msg.sender] = true;
    }

    function checkLeverageFarmingProtocol(address _sender) internal view {
        if (_sender != protocolAddr) revert InvalidCaller();
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
