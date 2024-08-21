// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IAddressRequests} from "src/interfaces/IAddressRequests.sol";

interface IETHx_Burner is IAddressRequests {
    error InsufficientWithdrawal();
    error InvalidHints();

    /**
     * @notice Emitted when a withdrawal is triggered.
     * @param caller caller of the function
     * @param requestIds request IDs that were created
     */
    event TriggerWithdrawal(address indexed caller, address[] requestIds);

    /**
     * @notice Emitted when a burn is triggered.
     * @param caller caller of the function
     * @param requestId request ID of the withdrawal that was claimed and burned
     */
    event TriggerBurn(address indexed caller, address requestId);

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
     * @notice Get a User Withdraw Manager request ID by address of the miniburner.
     * @param requestId address of the miniburner
     * @return User Withdraw Manager request ID
     */
    function requestIdInternal(address requestId) external view returns (uint256);

    /**
     * @notice Trigger a withdrawal of ETH from the collateral's underlying asset.
     * @param minWithdrawalAmount minimum amount of ETHx it is possible to withdraw
     * @param maxRequests maximum number of ETHx it is possible to withdraw in one request
     * @return requestIds request IDs that were created
     */
    function triggerWithdrawal(
        uint256 minWithdrawalAmount,
        uint256 maxWithdrawalAmount,
        uint256 maxRequests
    ) external returns (address[] memory requestIds);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(address requestId) external;
}
