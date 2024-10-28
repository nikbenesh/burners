// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "../common/SelfDestruct.sol";
import {UintRequests} from "../common/UintRequests.sol";

import {IETHx_Burner} from "../../interfaces/burners/ETHx/IETHx_Burner.sol";
import {IStaderConfig} from "../../interfaces/burners/ETHx/IStaderConfig.sol";
import {IStaderStakePoolsManager} from "../../interfaces/burners/ETHx/IStaderStakePoolsManager.sol";
import {IUserWithdrawalManager} from "../../interfaces/burners/ETHx/IUserWithdrawalManager.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

contract ETHx_Burner is UintRequests, Multicall, IETHx_Burner {
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IETHx_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IETHx_Burner
     */
    address public immutable STADER_CONFIG;

    /**
     * @inheritdoc IETHx_Burner
     */
    address public immutable USER_WITHDRAW_MANAGER;

    /**
     * @inheritdoc IETHx_Burner
     */
    address public immutable STAKE_POOLS_MANAGER;

    constructor(address collateral, address staderConfig) {
        COLLATERAL = collateral;

        STADER_CONFIG = staderConfig;
        USER_WITHDRAW_MANAGER = IStaderConfig(STADER_CONFIG).getUserWithdrawManager();
        STAKE_POOLS_MANAGER = IStaderConfig(STADER_CONFIG).getStakePoolManager();

        IERC20(COLLATERAL).approve(USER_WITHDRAW_MANAGER, type(uint256).max);
    }

    /**
     * @inheritdoc IETHx_Burner
     */
    function triggerWithdrawal(
        uint256 maxWithdrawalAmount
    ) external returns (uint256 requestId) {
        uint256 maxETHWithdrawAmount = IStaderConfig(STADER_CONFIG).getMaxWithdrawAmount();
        if (
            IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(maxWithdrawalAmount) > maxETHWithdrawAmount
                || IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(maxWithdrawalAmount + 1)
                    <= maxETHWithdrawAmount
        ) {
            revert InvalidETHxMaximumWithdrawal();
        }

        requestId = IUserWithdrawalManager(USER_WITHDRAW_MANAGER).requestWithdraw(
            Math.min(IERC20(COLLATERAL).balanceOf(address(this)), maxWithdrawalAmount), address(this)
        );

        _addRequestId(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc IETHx_Burner
     */
    function triggerBurn(
        uint256 requestId
    ) external {
        _requestIds.remove(requestId);

        IUserWithdrawalManager(USER_WITHDRAW_MANAGER).claim(requestId);

        new SelfDestruct{value: address(this).balance}();

        emit TriggerBurn(msg.sender, requestId);
    }

    receive() external payable {}
}
