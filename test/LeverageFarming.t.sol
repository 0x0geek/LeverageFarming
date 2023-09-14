// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import "../src/interfaces/IDiamondCut.sol";

import "../src/LeverageFarming.sol";
import "../src/AccountFactory.sol";

import "../src/facets/AaveFacet.sol";
import "../src/facets/AccountFacet.sol";
import "../src/facets/CompoundFacet.sol";
import "../src/facets/CurveFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "./utils/HelperContract.sol";

contract LeverageFarmingTest is Test, HelperContract {
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
    Account private account;

    string[] facetNameList;
    address[] facetAddressList;
    IDiamondCut.FacetCut[] diamondFacetCutList;
    BeaconProxy proxy;

    function setUp() public {
        aaveFacet = new AaveFacet();
        accountFacet = new AccountFacet();
        compoundFacet = new CompoundFacet();
        curveFacet = new CurveFacet();
        cutFacet = new DiamondCutFacet();
        loupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();

        facetNameList = [
            "AccountFacet",
            "AaveFacet",
            "CompoundFacet",
            "CurveFacet",
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet"
        ];

        facetAddressList = [
            address(accountFacet),
            address(aaveFacet),
            address(compoundFacet),
            address(curveFacet),
            address(cutFacet),
            address(loupeFacet),
            address(ownershipFacet)
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

        factory = new AccountFactory();

        proxy = new BeaconProxy(address(factory), "");
        // wrappedFactory = new AccountFactory(address(proxy));
        wrappedFactory.initialize(facetAddressList);

        farming = new LeverageFarming(address(wrappedFactory));
    }
}
