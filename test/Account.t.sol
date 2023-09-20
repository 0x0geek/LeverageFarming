// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "./utils/HelperContract.sol";

import "../src/libraries/LibFarmStorage.sol";

import "../src/interfaces/IDiamondCut.sol";

import "../src/facets/AaveFacet.sol";
import "../src/facets/AccountFacet.sol";
import "../src/facets/CompoundFacet.sol";
import "../src/facets/CurveFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/OwnershipFacet.sol";

import "../src/LeverageFarming.sol";
import "../src/AccountFactory.sol";
import "../src/AccountDiamond.sol";

import {BaseSetup} from "./BaseSetup.sol";

contract AccountDiamondTest is BaseSetup, HelperContract {
    AccountDiamond public account;
    LeverageFarming private farming;
    AccountFactory private factory;
    AccountFactory private wrappedFactory;
    AaveFacet private aaveFacet;
    AccountFacet private accountFacet;
    CompoundFacet private compoundFacet;
    CurveFacet private curveFacet;
    DiamondLoupeFacet private loupeFacet;
    DiamondCutFacet private cutFacet;
    OwnershipFacet private ownershipFacet;

    string[] facetNameList;
    address[] facetAddressList;
    IDiamondCut.FacetCut[] diamondFacetCutList;

    function setUp() public virtual override {
        BaseSetup.setUp();

        aaveFacet = new AaveFacet();
        accountFacet = new AccountFacet();
        compoundFacet = new CompoundFacet();
        curveFacet = new CurveFacet();
        cutFacet = new DiamondCutFacet();
        loupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();

        facetAddressList = [
            address(aaveFacet),
            address(accountFacet),
            address(compoundFacet),
            address(curveFacet),
            address(cutFacet),
            address(loupeFacet),
            address(ownershipFacet)
        ];

        facetNameList = [
            "AccountFacet",
            "AaveFacet",
            "CompoundFacet",
            "CurveFacet",
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet"
        ];

        uint facetLength = facetAddressList.length;

        for (uint i; i != facetLength; ++i) {
            IDiamondCut.FacetCut memory facetCut = IDiamondCut.FacetCut({
                facetAddress: address(facetAddressList[i]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: generateSelectors(facetNameList[i])
            });

            diamondFacetCutList.push(facetCut);
        }

        account = new AccountDiamond(diamondFacetCutList, address(this));
    }

    function test_AccountFacet_deposit() public {
        bytes memory funcCallData = abi.encodeWithSelector(
            bytes4(keccak256("deposit(uint8, uint256)")),
            0,
            100
        );

        vm.startPrank(alice);
        address accountFacet = facetAddressList[1];
        //callFacetFunction(accountFacet, funcCallData);
        vm.stopPrank();
    }

    function callFacetFunction(
        address _facet,
        bytes memory _calldata
    ) internal returns (bytes memory) {
        console.log("Sender = ", msg.sender);
        (bool success, bytes memory result) = _facet.delegatecall(_calldata);
        require(success, "Facet function call failed");
        return result;
    }
}
