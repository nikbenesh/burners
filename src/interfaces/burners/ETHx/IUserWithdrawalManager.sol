// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUserWithdrawalManager {
    function nextRequestId() external view returns (uint256);

    function nextRequestIdToFinalize() external view returns (uint256);

    /**
     * @notice put a withdrawal request
     * @param _ethXAmount amount of ethX shares to withdraw
     * @param _owner owner of withdraw request to redeem
     * @return requestId
     */
    function requestWithdraw(uint256 _ethXAmount, address _owner) external returns (uint256);

    /**
     * @notice finalize user requests
     * @dev check for safeMode to finalizeRequest
     */
    function finalizeUserWithdrawalRequest() external;

    /**
     * @notice transfer the eth of finalized request to recipient and delete the request
     * @param _requestId request id to redeem
     */
    function claim(
        uint256 _requestId
    ) external;
}
