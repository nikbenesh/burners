// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IAddressRequests} from "src/interfaces/IAddressRequests.sol";

interface IsUSDe_Burner is IAddressRequests {
    error HasCooldown();
    error InvalidAsset();
    error NoCooldown();
    error SufficientApproval();

    /**
     * @notice Emitted when a withdrawal is triggered.
     * @param caller caller of the function
     * @param amount amount of the collateral to be withdrawn
     * @param requestId request ID that was created
     */
    event TriggerWithdrawal(address indexed caller, uint256 amount, address requestId);

    /**
     * @notice Emitted when a claim is triggered.
     * @param caller caller of the function
     * @param requestId request ID of the withdrawal that was claimed
     */
    event TriggerClaim(address indexed caller, address requestId);

    /**
     * @notice Emitted when an instant claim is triggered.
     * @param caller caller of the function
     * @param amount amount of the collateral that was unwrapped
     */
    event TriggerInstantClaim(address indexed caller, uint256 amount);

    /**
     * @notice Emitted when a burn is triggered.
     * @param caller caller of the function
     * @param asset address of the asset burned (except sUSDe and USDe)
     * @param amount amount of the asset burned
     */
    event TriggerBurn(address indexed caller, address indexed asset, uint256 amount);

    /**
     * @notice Get an address of the collateral.
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
     * @notice Trigger a claim of USDe (if `cooldownDuration` didn't equal zero while triggering withdrawal).
     * @param requestId request ID of the withdrawal to process
     */
    function triggerClaim(address requestId) external;

    /**
     * @notice Trigger an instant claim of USDe (if `cooldownDuration` equals zero).
     */
    function triggerInstantClaim() external;

    /**
     * @notice Trigger a burn of any asset lying on this contract except sUSDe and USDe (after USDe redemption).
     * @param asset address of the asset to burn
     */
    function triggerBurn(address asset) external;

    /**
     * @notice Approve the USDe to a minter (if a new minter appears).
     */
    function approveUSDeMinter() external;
}
