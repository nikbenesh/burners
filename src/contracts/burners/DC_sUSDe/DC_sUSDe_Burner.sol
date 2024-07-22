// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {DC_sUSDe_Miniburner} from "./DC_sUSDe_Miniburner.sol";

import {IDC_sUSDe_Burner} from "src/interfaces/burners/DC_sUSDe/IDC_sUSDe_Burner.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract DC_sUSDe_Burner is IDC_sUSDe_Burner {
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones for address;

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    address public immutable ASSET;

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    address public immutable MINIBURNER_IMPLEMENTATION;

    EnumerableSet.AddressSet private _requestIds;

    constructor(address collateral, address implementation) {
        COLLATERAL = collateral;

        ASSET = IDefaultCollateral(collateral).asset();

        MINIBURNER_IMPLEMENTATION = implementation;
    }

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    function requestIdsLength() external view returns (uint256) {
        return _requestIds.length();
    }

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    function requestIds(uint256 index, uint256 maxRequestIds) external view returns (address[] memory requestIds_) {
        uint256 length = Math.min(index + maxRequestIds, _requestIds.length()) - index;

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
     * @inheritdoc IDC_sUSDe_Burner
     */
    function triggerWithdrawal() external returns (address requestId) {
        requestId = MINIBURNER_IMPLEMENTATION.clone();

        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));
        IDefaultCollateral(COLLATERAL).withdraw(requestId, amount);

        DC_sUSDe_Miniburner(requestId).initialize(amount);

        _requestIds.add(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    function triggerBurn(address requestId) external {
        if (!_requestIds.remove(requestId)) {
            revert InvalidRequestId();
        }

        DC_sUSDe_Miniburner(requestId).triggerBurn();

        emit TriggerBurn(msg.sender, requestId);
    }
}
