// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";

import {IDC_ETHx_Burner} from "src/interfaces/burners/DC_ETHx/IDC_ETHx_Burner.sol";
import {IStaderStakePoolsManager} from "src/interfaces/burners/DC_ETHx/IStaderStakePoolsManager.sol";
import {IUserWithdrawalManager} from "src/interfaces/burners/DC_ETHx/IUserWithdrawalManager.sol";
import {IStaderConfig} from "src/interfaces/burners/DC_ETHx/IStaderConfig.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DC_ETHx_Burner is IDC_ETHx_Burner {
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    address public immutable ASSET;

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    address public immutable STADER_CONFIG;

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    address public immutable USER_WITHDRAW_MANAGER;

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    address public immutable STAKE_POOLS_MANAGER;

    EnumerableSet.UintSet private _requestIds;

    constructor(address collateral, address staderConfig) {
        COLLATERAL = collateral;

        ASSET = IDefaultCollateral(collateral).asset();

        STADER_CONFIG = staderConfig;
        USER_WITHDRAW_MANAGER = IStaderConfig(STADER_CONFIG).getUserWithdrawManager();
        STAKE_POOLS_MANAGER = IStaderConfig(STADER_CONFIG).getStakePoolManager();

        IERC20(ASSET).approve(USER_WITHDRAW_MANAGER, type(uint256).max);
    }

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    function requestIdsLength() external view returns (uint256) {
        return _requestIds.length();
    }

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    function requestIds(uint256 index, uint256 maxRequestIds) external view returns (uint256[] memory requestIds_) {
        uint256 length = Math.min(index + maxRequestIds, _requestIds.length()) - index;

        requestIds_ = new uint256[](length);
        for (uint256 i; i < length;) {
            requestIds_[i] = _requestIds.at(index);
            unchecked {
                ++i;
                ++index;
            }
        }
    }

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    function triggerWithdrawal(uint256 maxRequests) external returns (uint256 firstRequestId, uint256 lastRequestId) {
        IDefaultCollateral(COLLATERAL).withdraw(address(this), IERC20(COLLATERAL).balanceOf(address(this)));
        uint256 amount = IERC20(ASSET).balanceOf(address(this));

        uint256 maxWithdrawalAmount = IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewDeposit(
            IStaderConfig(STADER_CONFIG).getMaxWithdrawAmount()
        );
        uint256 minWithdrawalAmount = IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewDeposit(
            IStaderConfig(STADER_CONFIG).getMinWithdrawAmount()
        ) + 1;

        uint256 requests = amount / maxWithdrawalAmount;
        if (amount % maxWithdrawalAmount >= minWithdrawalAmount) {
            requests += 1;
        }
        requests = Math.min(requests, maxRequests);

        if (requests == 0) {
            revert InsufficientWithdrawal();
        }

        uint256 requestsMinusOne = requests - 1;
        firstRequestId = IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestId();
        lastRequestId = firstRequestId + requestsMinusOne;
        uint256 requestId = firstRequestId;
        for (; requestId < lastRequestId; ++requestId) {
            _requestIds.add(requestId);
            IUserWithdrawalManager(USER_WITHDRAW_MANAGER).requestWithdraw(maxWithdrawalAmount, address(this));
        }
        _requestIds.add(requestId);
        IUserWithdrawalManager(USER_WITHDRAW_MANAGER).requestWithdraw(
            Math.min(amount - requestsMinusOne * maxWithdrawalAmount, maxWithdrawalAmount), address(this)
        );

        emit TriggerWithdrawal(msg.sender, firstRequestId, lastRequestId);

        return (firstRequestId, lastRequestId);
    }

    /**
     * @inheritdoc IDC_ETHx_Burner
     */
    function triggerBurn(uint256 requestId) external {
        if (!_requestIds.remove(requestId)) {
            revert InvalidRequestId();
        }

        IUserWithdrawalManager(USER_WITHDRAW_MANAGER).claim(requestId);

        new SelfDestruct{value: address(this).balance}();

        emit TriggerBurn(msg.sender, requestId);
    }

    receive() external payable {}
}
