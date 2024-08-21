// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IUintRequests} from "src/interfaces/IUintRequests.sol";

interface IETHx_Burner is IUintRequests {
    error InsufficientWithdrawal();
    error InvalidHints();

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
     * @notice Get an address of the Stader Config contract.
     */
    function STADER_CONFIG() external view returns (address);

    /**
     * @notice Get an address of the User Withdraw Manager contract.
     */
    function USER_WITHDRAW_MANAGER() external view returns (address);

    /**
     * @notice Get an address of the Stake Pools Manager contract.
     */
    function STAKE_POOLS_MANAGER() external view returns (address);

    /**
     * @notice Trigger a withdrawal of ETH from the collateral's underlying asset.
     * @param minWithdrawalAmount minimum amount of ETHx it is possible to withdraw
     * @param maxRequests maximum number of ETHx it is possible to withdraw in one request
     * @return firstRequestId first request ID that was created
     * @return lastRequestId last request ID that was created
     */
    function triggerWithdrawal(
        uint256 minWithdrawalAmount,
        uint256 maxWithdrawalAmount,
        uint256 maxRequests
    ) external returns (uint256 firstRequestId, uint256 lastRequestId);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(uint256 requestId) external;
}
