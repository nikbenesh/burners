// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaderConfig {
    function getUserWithdrawManager() external view returns (address);

    function getStakePoolManager() external view returns (address);

    function getMinWithdrawAmount() external view returns (uint256);

    function getMaxWithdrawAmount() external view returns (uint256);

    function getMinBlockDelayToFinalizeWithdrawRequest() external view returns (uint256);
}
