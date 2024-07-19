// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDC_rETH_Burner {
    error InsufficientBurn();

    /**
     * @notice Emitted when a burn is triggered.
     * @param caller caller of the function
     * @param assetAmount amount of collateral that was withdrawn
     * @param ethAmount amount of ETH that was burned
     */
    event TriggerBurn(address indexed caller, uint256 assetAmount, uint256 ethAmount);

    /**
     * @notice Get an address of the Default Collateral contract.
     */
    function COLLATERAL() external view returns (address);

    /**
     * @notice Get an address of the collateral's asset.
     */
    function ASSET() external view returns (address);

    /**
     * @notice Trigger a claim and a burn of ETH.
     * @param amount amount of collateral to burn
     */
    function triggerBurn(uint256 amount) external;
}
