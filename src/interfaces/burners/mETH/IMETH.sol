// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMETH {
    /// @notice The staking contract which has permissions to mint tokens.
    function stakingContract() external view returns (address);

    /// @notice Mint mETH to the staker.
    /// @param staker The address of the staker.
    /// @param amount The amount of tokens to mint.
    /// @dev Expected to be called during the stake operation.
    function mint(address staker, uint256 amount) external;
}
