// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/LibFarmStorage.sol";
import "./interfaces/IAccountFactory.sol";

import "./AccountFactory.sol";

contract LeverageFarming is Ownable, ReentrancyGuard {
    IAccountFactory public accountFactory;

    constructor(address _accFactoryAddr) {
        accountFactory = IAccountFactory(_accFactoryAddr);
    }

    function setInterestRate(uint256 _interestRate) external onlyOwner {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        fs.interestRate = _interestRate;
    }

    function setFacetAddrs(address[] memory _facetAddrs) external onlyOwner {
        accountFactory.setFacetAddrs(_facetAddrs);
    }

    function setSupportedToken(
        address _token,
        bool _supported
    ) external onlyOwner {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        fs.supportedTokens[_token] = _supported;
    }

    function addPool(address _token) external onlyOwner {
        LibFarmStorage.Storage storage fs = LibFarmStorage.farmStorage();
        // fs.pools[_token] = Pool({balance: 0, interest: 0});
    }
}
