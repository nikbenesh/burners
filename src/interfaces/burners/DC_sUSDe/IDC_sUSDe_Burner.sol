// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IAddressRequests} from "src/interfaces/IAddressRequests.sol";

interface IDC_sUSDe_Burner is IAddressRequests {
    error HasCooldown();
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
     * @notice Get an address of the USDe contract.
     */
    function USDE() external view returns (address);

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
