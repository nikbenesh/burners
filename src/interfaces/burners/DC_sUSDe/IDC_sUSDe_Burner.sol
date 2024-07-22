// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDC_sUSDe_Burner {
    error HasCooldown();
    error InvalidRequestId();
    error NoCooldown();

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
     * @notice Emitted when an instant burn is triggered.
     * @param caller caller of the function
     * @param amount amount of the collateral that was burned
     */
    event TriggerInstantBurn(address indexed caller, uint256 amount);

    /**
     * @notice Get an address of the Default Collateral contract.
     */
    function COLLATERAL() external view returns (address);

    /**
     * @notice Get an address of the collateral's asset.
     */
    function ASSET() external view returns (address);

    /**
     * @notice Get an address of the USDe contract.
     */
    function USDE() external view returns (address);

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

    /**
     * @notice Trigger an instant burn of USDe.
     */
    function triggerInstantBurn() external;
}
