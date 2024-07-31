// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IStaderStakePoolsManager {
    // returns the amount of share corresponding to `_assets` assets
    function previewDeposit(uint256 _assets) external view returns (uint256);

    // return the amount of assets corresponding to `_shares` shares
    function previewWithdraw(uint256 _shares) external view returns (uint256);
}
