// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDC_sUSDe_Burner {
    error InvalidRequestId();

    /**
     * @notice Emitted when a withdrawal is triggered.
     * @param caller caller of the function
     * @param requestId request ID that was created
     */
    event TriggerWithdrawal(address indexed caller, address requestId);

    /**
     * @notice Emitted when a burn is triggered.
     * @param caller caller of the function
     * @param requestId request ID of the withdrawal that was claimed and burned
     */
    event TriggerBurn(address indexed caller, address requestId);

    /**
     * @notice Get an address of the Default Collateral contract.
     */
    function COLLATERAL() external view returns (address);

    /**
     * @notice Get an address of the collateral's asset.
     */
    function ASSET() external view returns (address);

    /**
     * @notice Get an implementation of Miniburner.
     */
    function MINIBURNER_IMPLEMENTATION() external view returns (address);

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
    function requestIds(uint256 index, uint256 maxRequestIds) external view returns (address[] memory requestIds);

    /**
     * @notice Trigger a withdrawal of USDe from the collateral's underlying asset.
     * @return requestId request ID that was created
     */
    function triggerWithdrawal() external returns (address requestId);

    /**
     * @notice Trigger a claim and a burn of USDe.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(address requestId) external;
}
