// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IUintRequests} from "../../IUintRequests.sol";

interface IETHx_Burner is IUintRequests {
    error InvalidETHxMaximumWithdrawal();

    /**
     * @notice Emitted when a withdrawal is triggered.
     * @param caller caller of the function
     * @param requestId request ID that was created
     */
    event TriggerWithdrawal(address indexed caller, uint256 requestId);

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
     * @param maxWithdrawalAmount maximum amount of ETHx it is possible to withdraw in one request
     * @return requestId request ID that was created
     */
    function triggerWithdrawal(
        uint256 maxWithdrawalAmount
    ) external returns (uint256 requestId);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(
        uint256 requestId
    ) external;
}
