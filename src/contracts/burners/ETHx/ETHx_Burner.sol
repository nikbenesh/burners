// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {AddressRequests} from "src/contracts/AddressRequests.sol";

import {IETHx_Burner} from "src/interfaces/burners/ETHx/IETHx_Burner.sol";
import {IETHx_Miniburner} from "src/interfaces/burners/ETHx/IETHx_Miniburner.sol";
import {IStaderConfig} from "src/interfaces/burners/ETHx/IStaderConfig.sol";
import {IStaderStakePoolsManager} from "src/interfaces/burners/ETHx/IStaderStakePoolsManager.sol";
import {IUserWithdrawalManager} from "src/interfaces/burners/ETHx/IUserWithdrawalManager.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ETHx_Burner is AddressRequests, IETHx_Burner {
    using Clones for address;
    using Math for uint256;

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

    address private immutable _MINIBURNER_IMPLEMENTATION;

    /**
     * @inheritdoc IETHx_Burner
     */
    mapping(address requestId => uint256 value) public requestIdInternal;

    constructor(address collateral, address staderConfig, address miniburner_implementation) {
        COLLATERAL = collateral;

        STADER_CONFIG = staderConfig;
        USER_WITHDRAW_MANAGER = IStaderConfig(STADER_CONFIG).getUserWithdrawManager();
        STAKE_POOLS_MANAGER = IStaderConfig(STADER_CONFIG).getStakePoolManager();

        _MINIBURNER_IMPLEMENTATION = miniburner_implementation;

        IERC20(COLLATERAL).approve(USER_WITHDRAW_MANAGER, type(uint256).max);
    }

    /**
     * @inheritdoc IETHx_Burner
     */
    function triggerWithdrawal(
        uint256 minWithdrawalAmount,
        uint256 maxWithdrawalAmount,
        uint256 maxRequests
    ) external returns (address[] memory requestIds) {
        uint256 minETHWithdrawAmount = IStaderConfig(STADER_CONFIG).getMinWithdrawAmount();
        uint256 maxETHWithdrawAmount = IStaderConfig(STADER_CONFIG).getMaxWithdrawAmount();
        if (
            IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(minWithdrawalAmount) < minETHWithdrawAmount
                || IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(minWithdrawalAmount - 1)
                    >= minETHWithdrawAmount
                || IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(maxWithdrawalAmount) > maxETHWithdrawAmount
                || IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(maxWithdrawalAmount + 1)
                    <= maxETHWithdrawAmount
        ) {
            revert InvalidHints();
        }

        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));

        uint256 requests = amount / maxWithdrawalAmount;
        if (amount % maxWithdrawalAmount >= minWithdrawalAmount) {
            requests += 1;
        }
        requests = Math.min(requests, maxRequests);

        if (requests == 0) {
            revert InsufficientWithdrawal();
        }

        requestIds = new address[](requests);
        uint256 requestsMinusOne = requests - 1;
        for (uint256 i; i < requestsMinusOne; ++i) {
            requestIds[i] = _createRequest(maxWithdrawalAmount);
        }
        requestIds[requestsMinusOne] =
            _createRequest(Math.min(amount - requestsMinusOne * maxWithdrawalAmount, maxWithdrawalAmount));

        emit TriggerWithdrawal(msg.sender, requestIds);
    }

    /**
     * @inheritdoc IETHx_Burner
     */
    function triggerBurn(address requestId) external {
        _removeRequestId(requestId);

        IETHx_Miniburner(requestId).triggerBurn(requestIdInternal[requestId]);

        emit TriggerBurn(msg.sender, requestId);
    }

    function _createRequest(uint256 amount) private returns (address requestId) {
        requestId = _MINIBURNER_IMPLEMENTATION.clone();
        IETHx_Miniburner(requestId).initialize();

        requestIdInternal[requestId] = IUserWithdrawalManager(USER_WITHDRAW_MANAGER).requestWithdraw(amount, requestId);

        _addRequestId(requestId);
    }
}
