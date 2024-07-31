// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDC_sfrxETH_Burner {
    error InvalidRequestId();

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
     * @notice Get an address of the Default Collateral contract.
     */
    function COLLATERAL() external view returns (address);

    /**
     * @notice Get an address of the Frax Ether Redemption queue.
     */
    function FRAX_ETHER_REDEMPTION_QUEUE() external view returns (address);

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
     * @return requestId request ID that was created
     */
    function triggerWithdrawal() external returns (uint256 requestId);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param requestId request ID of the withdrawal to process
     */
    function triggerBurn(uint256 requestId) external;
}
