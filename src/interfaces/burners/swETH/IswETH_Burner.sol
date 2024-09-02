// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IUintRequests} from "../../IUintRequests.sol";

interface IswETH_Burner is IUintRequests {
    error InsufficientWithdrawal();

    /**
     * @notice Emitted when a withdrawal is triggered.
     * @param caller caller of the function
     * @param firstRequestId first request ID that was created
     * @param lastRequestId last request ID that was created
     */
    event TriggerWithdrawal(address indexed caller, uint256 firstRequestId, uint256 lastRequestId);

    /**
     * @notice Emitted when a burn is triggered.
     * @param caller caller of the function
     * @param requestId request ID of the withdrawal that was claimed and burned
     */
    event TriggerBurn(address indexed caller, uint256 requestId);

    /**
     * @notice Get an address of the collateral.
     */
    function COLLATERAL() external view returns (address);

    /**
     * @notice Get an address of the Swell Exit contract.
     */
    function SWEXIT() external view returns (address);

    /**
     * @notice Trigger a withdrawal of ETH from the collateral's underlying asset.
     * @param maxRequests maximum number of withdrawal requests to create
     * @return firstRequestId first request ID that was created
     * @return lastRequestId last request ID that was created
     */
    function triggerWithdrawal(
        uint256 maxRequests
    ) external returns (uint256 firstRequestId, uint256 lastRequestId);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(
        uint256 requestId
    ) external;
}
