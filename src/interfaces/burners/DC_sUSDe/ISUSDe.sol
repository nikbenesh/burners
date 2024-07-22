// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ISUSDe {
    /**
     * @dev See {IERC4626-asset}.
     */
    function asset() external view returns (address);

    function cooldownDuration() external view returns (uint24);

    /// @notice redeem shares into assets and starts a cooldown to claim the converted underlying asset
    /// @param shares shares to redeem
    function cooldownShares(uint256 shares) external returns (uint256 assets);

    /**
     * @dev See {IERC4626-previewRedeem}.
     */
    function previewRedeem(uint256 shares) external returns (uint256);

    /// @notice Set cooldown duration. If cooldown duration is set to zero, the StakedUSDeV2 behavior changes to follow ERC4626 standard and disables cooldownShares and cooldownAssets methods. If cooldown duration is greater than zero, the ERC4626 withdrawal and redeem functions are disabled, breaking the ERC4626 standard, and enabling the cooldownShares and the cooldownAssets functions.
    /// @param duration Duration of the cooldown
    function setCooldownDuration(uint24 duration) external;

    /**
     * @dev See {IERC4626-deposit}.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256);

    /**
     * @dev See {IERC4626-redeem}.
     */
    function redeem(uint256 shares, address receiver, address _owner) external returns (uint256);

    /// @notice Claim the staking amount after the cooldown has finished. The address can only retire the full amount of assets.
    /// @dev unstake can be called after cooldown have been set to 0, to let accounts to be able to claim remaining assets locked at Silo
    /// @param receiver Address to send the assets by the staker
    function unstake(address receiver) external;
}
