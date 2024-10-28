// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRocketTokenRETH {
    // Calculate the amount of ETH backing an amount of rETH
    function getEthValue(
        uint256 _rethAmount
    ) external view returns (uint256);

    // Calculate the amount of rETH backed by an amount of ETH
    function getRethValue(
        uint256 _ethAmount
    ) external view returns (uint256);

    // Get the total amount of collateral available
    // Includes rETH contract balance & excess deposit pool balance
    function getTotalCollateral() external view returns (uint256);

    // Mint rETH
    // Only accepts calls from the RocketDepositPool contract
    function mint(uint256 _ethAmount, address _to) external;

    // Burn rETH for ETH
    function burn(
        uint256 _rethAmount
    ) external;
}
