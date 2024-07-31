// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IFraxEtherRedemptionQueue {
    /// @notice State of Frax's frxETH redemption queue
    /// @return nextNftId Autoincrement for the NFT id
    /// @return queueLengthSecs Current wait time (in seconds) a new redeemer would have. Should be close to Beacon.
    /// @return redemptionFee Redemption fee given as a percentage with 1e6 precision
    /// @return earlyExitFee Early NFT back to frxETH exit fee given as a percentage with 1e6 precision
    function redemptionQueueState()
        external
        view
        returns (uint64 nextNftId, uint64 queueLengthSecs, uint64 redemptionFee, uint64 earlyExitFee);

    /// @notice Enter the queue for redeeming sfrxEth to frxETH at the current rate, then frxETH to ETH 1-to-1. Must have approved or permitted first.
    /// @notice Will generate a FrxETHRedemptionTicket NFT that can be redeemed for the actual ETH later.
    /// @param _recipient Recipient of the NFT. Must be ERC721 compatible if a contract
    /// @param _sfrxEthAmount Amount of sfrxETH to redeem (in shares / balanceOf)
    /// @param _nftId The ID of the FrxEthRedemptionTicket NFT
    /// @dev Must call approve/permit on frxEth contract prior to this call
    function enterRedemptionQueueViaSfrxEth(
        address _recipient,
        uint120 _sfrxEthAmount
    ) external returns (uint256 _nftId);

    /// @notice Redeems a FrxETHRedemptionTicket NFT for ETH. Must have reached the maturity date first.
    /// @param _nftId The ID of the NFT
    /// @param _recipient The recipient of the redeemed ETH
    function burnRedemptionTicketNft(uint256 _nftId, address payable _recipient) external;
}
