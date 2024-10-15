// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IUintRequests} from "../../common/IUintRequests.sol";

interface IwstETH_Burner is IUintRequests {
    error InsufficientWithdrawal();

    /**
     * @notice Emitted when a withdrawal is triggered.
     * @param caller caller of the function
     * @param requestIds request IDs that were created
     */
    event TriggerWithdrawal(address indexed caller, uint256[] requestIds);

    /**
     * @notice Emitted when a burn is triggered.
     * @param caller caller of the function
     * @param requestId request ID of the withdrawal that was claimed and burned
     */
    event TriggerBurn(address indexed caller, uint256 requestId);

    /**
     * @notice Emitted when a batch burn is triggered.
     * @param caller caller of the function
     * @param requestIds request IDs of the withdrawals that were claimed and burned
     */
    event TriggerBurnBatch(address indexed caller, uint256[] requestIds);

    /**
     * @notice Get an address of the collateral.
     */
    function COLLATERAL() external view returns (address);

    /**
     * @notice Get an address of the stETH token.
     */
    function STETH() external view returns (address);

    /**
     * @notice Get an address of the Lido Withdrawal Queue.
     */
    function LIDO_WITHDRAWAL_QUEUE() external view returns (address);

    /**
     * @notice Get a minimum amount of stETH that can be withdrawn at a request.
     */
    function MIN_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    /**
     * @notice Get a maximum amount of stETH that can be withdrawn at a request.
     */
    function MAX_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    /**
     * @notice Trigger a withdrawal of ETH from the collateral's underlying asset.
     * @param maxRequests maximum number of withdrawal requests to create
     * @return requestIds request IDs that were created
     */
    function triggerWithdrawal(
        uint256 maxRequests
    ) external returns (uint256[] memory requestIds);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(
        uint256 requestId
    ) external;

    /**
     * @notice Trigger a batch claim and burn of ETH.
     * @param requestIds request IDs of the withdrawals to process
     * @param hints hints for the requests
     */
    function triggerBurnBatch(uint256[] calldata requestIds, uint256[] calldata hints) external;
}
