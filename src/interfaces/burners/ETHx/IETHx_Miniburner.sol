// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IETHx_Miniburner {
    function initialize() external;

    function triggerBurn(uint256 requestId) external;
}
