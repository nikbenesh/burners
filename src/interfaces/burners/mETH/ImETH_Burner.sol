// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IUintRequests} from "src/interfaces/IUintRequests.sol";

interface ImETH_Burner is IUintRequests {
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
     * @notice Get an address of the Mantle Staking contract.
     */
    function STAKING() external view returns (address);

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
