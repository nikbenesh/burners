// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IWithdrawalQueue {
    /// @notice Lido stETH token address
    function STETH() external view returns (address);

    /// @notice minimal amount of stETH that is possible to withdraw
    function MIN_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    /// @notice maximum amount of stETH that is possible to withdraw by a single request
    /// Prevents accumulating too much funds per single request fulfillment in the future.
    /// @dev To withdraw larger amounts, it's recommended to split it to several requests
    function MAX_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    /// @notice id of the last request
    ///  NB! requests are indexed from 1, so it returns 0 if there is no requests in the queue
    function getLastRequestId() external view returns (uint256);

    /// @notice Request the batch of stETH for withdrawal. Approvals for the passed amounts should be done before.
    /// @param _amounts an array of stETH amount values.
    ///  The standalone withdrawal request will be created for each item in the passed list.
    /// @param _owner address that will be able to manage the created requests.
    ///  If `address(0)` is passed, `msg.sender` will be used as owner.
    /// @return requestIds an array of the created withdrawal request ids
    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /// @notice Claim a batch of withdrawal requests if they are finalized sending locked ether to the owner
    /// @param _requestIds array of request ids to claim
    /// @param _hints checkpoint hint for each id. Can be obtained with `findCheckpointHints()`
    /// @dev
    ///  Reverts if requestIds and hints arrays length differs
    ///  Reverts if any requestId or hint in arguments are not valid
    ///  Reverts if any request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of the requests
    function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata _hints) external;

    /// @notice Claim one`_requestId` request once finalized sending locked ether to the owner
    /// @param _requestId request id to claim
    /// @dev use unbounded loop to find a hint, which can lead to OOG
    /// @dev
    ///  Reverts if requestId or hint are not valid
    ///  Reverts if request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of request
    function claimWithdrawal(
        uint256 _requestId
    ) external;

    /// @notice Finalize requests from last finalized one up to `_lastRequestIdToBeFinalized`
    /// @dev ether to finalize all the requests should be calculated using `prefinalize()` and sent along
    function finalize(uint256 _lastRequestIdToBeFinalized, uint256 _maxShareRate) external payable;

    /// @notice length of the checkpoint array. Last possible value for the hint.
    ///  NB! checkpoints are indexed from 1, so it returns 0 if there is no checkpoints
    function getLastCheckpointIndex() external view returns (uint256);

    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices
    ///  in the range  `[_firstIndex, _lastIndex]`.
    ///  NB! Array of request ids should be sorted
    ///  NB! `_firstIndex` should be greater than 0, because checkpoint list is 1-based array
    ///  Usage: findCheckpointHints(_requestIds, 1, getLastCheckpointIndex())
    /// @param _requestIds ids of the requests sorted in the ascending order to get hints for
    /// @param _firstIndex left boundary of the search range. Should be greater than 0
    /// @param _lastIndex right boundary of the search range. Should be less than or equal to getLastCheckpointIndex()
    /// @return hintIds array of hints used to find required checkpoint for the request
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    ) external view returns (uint256[] memory hintIds);
}
