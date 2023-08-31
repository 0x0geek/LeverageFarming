// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Account.sol";
import "./libraries/LibFarmStorage.sol";
import "./interfaces/IDiamondCut.sol";

contract AccountFactory is Ownable {
    address public protocolAddr;
    address[] public facetAddrs;

    error AccountAlreadyExist();
    error InvalidCaller();

    modifier onlyLeverageFarmingProtocol() {
        checkLeverageFarmingProtocol(msg.sender);
        _;
    }

    constructor(address[] memory _facetAddrs) {
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

        if (fs.accounts[msg.sender] != address(0)) revert AccountAlreadyExist();

        uint256 facetLength = facetAddrs.length;

        IDiamondCut.FacetCut[] memory diamondCut = new IDiamondCut.FacetCut[](
            facetLength
        );

        for (uint256 i; i != facetLength; ++i) {
            diamondCut[i] = IDiamondCut.FacetCut({
                facetAddress: facetAddrs[i],
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: new bytes4[](0)
            });
        }

        Account account = new Account();
        account.initialize(diamondCut, msg.sender);

        fs.accounts[msg.sender] = address(account);
    }

    function checkLeverageFarmingProtocol(address _sender) internal view {
        if (_sender != protocolAddr) revert InvalidCaller();
    }
}
