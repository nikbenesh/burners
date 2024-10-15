// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    /// @notice The minimum amount of mETH users can unstake.
    function minimumUnstakeBound() external view returns (uint256);

    /// @notice Converts from ETH to mETH using the current exchange rate.
    /// The exchange rate is given by the total supply of mETH and total ETH controlled by the protocol.
    function mETHToETH(
        uint256 mETHAmount
    ) external view returns (uint256);

    /// @notice Interface for users to submit a request to unstake.
    /// @dev Transfers the specified amount of mETH to the staking contract and locks it there until it is burned on
    /// request claim. The staking contract must therefore be approved to move the user's mETH on their behalf.
    /// @param methAmount The amount of mETH to unstake.
    /// @param minETHAmount The minimum amount of ETH that the user expects to receive.
    /// @return The request ID.
    function unstakeRequest(uint128 methAmount, uint128 minETHAmount) external returns (uint256);

    /// @notice Interface for users to claim their finalized and filled unstaking requests.
    /// @dev See also {UnstakeRequestsManager} for a more detailed explanation of finalization and request filling.
    function claimUnstakeRequest(
        uint256 unstakeRequestID
    ) external;
}
