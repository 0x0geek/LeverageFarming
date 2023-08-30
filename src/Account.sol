// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin-upgrade/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrade/contracts/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IDiamondCut.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./libraries/LibDiamond.sol";
import "./libraries/LibOwnership.sol";
import "./libraries/LibDiamondStorage.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC173.sol";
import "./VersionAware.sol";

contract Account is Initializable, ReentrancyGuardUpgradeable, VersionAware {
    function initialize(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _owner
    ) external initializer {
        require(_owner != address(0), "owner must not be 0x0");

        // owner = _owner;
        versionAwareContractName = "Beacon Proxy Pattern: V1";

        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibOwnership.setContractOwner(_owner);

        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            .diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            .diamondStorage();

        address facet = address(bytes20(ds.facets[msg.sig].facetAddress));
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function getContractNameWithVersion()
        public
        pure
        override
        returns (string memory)
    {
        return "Beacon Proxy Pattern: V1";
    }

    receive() external payable {}
}
