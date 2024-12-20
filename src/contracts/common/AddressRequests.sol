// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IAddressRequests} from "../../interfaces/common/IAddressRequests.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract AddressRequests is IAddressRequests {
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _requestIds;

    /**
     * @inheritdoc IAddressRequests
     */
    function requestIdsLength() external view returns (uint256) {
        return _requestIds.length();
    }

    /**
     * @inheritdoc IAddressRequests
     * @dev Returns a list of request IDs starting from the specified index up to maxRequestIds.
     * If maxRequestIds exceeds the remaining items, only available items are returned.
     */
    function requestIds(uint256 index, uint256 maxRequestIds) external view returns (address[] memory requestIds_) {
        // Ensure index is within bounds
        require(index < _requestIds.length(), "Index out of bounds");

        // Calculate the actual length of the returned array
        uint256 length = Math.min(index + maxRequestIds, _requestIds.length()) - index;

        // Initialize the array with the calculated length
        requestIds_ = new address[](length);
        for (uint256 i; i < length;) {
            requestIds_[i] = _requestIds.at(index);
            unchecked {
                ++i;
                ++index;
            }
        }
    }

    /**
     * @dev Internal function to add a request ID to the set.
     * @param requestId The address to be added as a request ID.
     */
    function _addRequestId(address requestId) internal {
        // Ensure that the requestId is not zero address
        require(requestId != address(0), "Invalid address: zero address");
        _requestIds.add(requestId);
    }

    /**
     * @dev Internal function to remove a request ID from the set.
     * @param requestId The address to be removed as a request ID.
     */
    function _removeRequestId(address requestId) internal {
        // Ensure that the requestId is not zero address
        require(requestId != address(0), "Invalid address: zero address");
        if (!_requestIds.remove(requestId)) {
            revert InvalidRequestId();
        }
    }

    // Custom error for invalid request IDs
    error InvalidRequestId();
}

