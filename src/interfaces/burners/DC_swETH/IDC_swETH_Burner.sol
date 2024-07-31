// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDC_swETH_Burner {
    error InsufficientWithdrawal();
    error InvalidRequestId();

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
     * @notice Get an address of the Default Collateral contract.
     */
    function COLLATERAL() external view returns (address);

    /**
     * @notice Get an address of the Swell Exit contract.
     */
    function SWEXIT() external view returns (address);

    /**
     * @notice Get the number of unprocessed request IDs.
     */
    function requestIdsLength() external view returns (uint256);

    /**
     * @notice Get a list of unprocessed request IDs.
     * @param index index of the first request ID
     * @param maxRequestIds maximum number of request IDs to return
     * @return requestIds request IDs
     */
    function requestIds(uint256 index, uint256 maxRequestIds) external view returns (uint256[] memory requestIds);

    /**
     * @notice Trigger a withdrawal of ETH from the collateral's underlying asset.
     * @param maxRequests maximum number of withdrawal requests to create
     * @return firstRequestId first request ID that was created
     * @return lastRequestId last request ID that was created
     */
    function triggerWithdrawal(uint256 maxRequests) external returns (uint256 firstRequestId, uint256 lastRequestId);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(uint256 requestId) external;
}
