// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

interface ICurveMinter {
    function mint_for(address, address) external;

    function mint(address) external;
}

interface ICurvePool {
    function add_liquidity(
        uint256[3] memory,
        uint256,
        bool
    ) external returns (uint256);

    function add_liquidity(
        uint256[3] memory,
        uint256
    ) external returns (uint256);

    function remove_liquidity(
        uint256,
        uint256[3] memory
    ) external returns (uint256[3] memory);

    function lp_token() external returns (address);
}

interface ILiquidityGauge {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function claimable_tokens(address) external returns (uint256);

    function claimable_reward(address) external returns (uint256);

    function claim_rewards(address) external;

    function integrate_fraction(
        address _account
    ) external view returns (uint256);
}
