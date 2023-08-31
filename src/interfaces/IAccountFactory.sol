// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

interface IAccountFactory {
    function setFacetAddrs(address[] memory _facetAddrs) external;
}
