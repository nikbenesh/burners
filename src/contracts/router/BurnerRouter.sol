// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IBurnerRouter} from "../../interfaces/router/IBurnerRouter.sol";

import {IBurner} from "@symbioticfi/core/src/interfaces/slasher/IBurner.sol";
import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

contract BurnerRouter is OwnableUpgradeable, IBurnerRouter {
    using Subnetwork for bytes32;
    using SafeERC20 for IERC20;

    /**
     * @inheritdoc IBurnerRouter
     */
    address public collateral;

    /**
     * @inheritdoc IBurnerRouter
     */
    uint256 public lastBalance;

    /**
     * @inheritdoc IBurnerRouter
     */
    Uint48 public delay;

    /**
     * @inheritdoc IBurnerRouter
     */
    PendingUint48 public pendingDelay;

    /**
     * @inheritdoc IBurnerRouter
     */
    Address public globalReceiver;

    /**
     * @inheritdoc IBurnerRouter
     */
    PendingAddress public pendingGlobalReceiver;

    /**
     * @inheritdoc IBurnerRouter
     */
    mapping(address network => Address receiver) public networkReceiver;

    /**
     * @inheritdoc IBurnerRouter
     */
    mapping(address network => PendingAddress pendingReceiver) public pendingNetworkReceiver;

    /**
     * @inheritdoc IBurnerRouter
     */
    mapping(address network => mapping(address operator => Address receiver)) public operatorNetworkReceiver;

    /**
     * @inheritdoc IBurnerRouter
     */
    mapping(address network => mapping(address operator => PendingAddress pendingReceiver)) public
        pendingOperatorNetworkReceiver;

    /**
     * @inheritdoc IBurnerRouter
     */
    mapping(address receiver => uint256 amount) public balanceOf;

    /**
     * @inheritdoc IBurner
     */
    function onSlash(
        bytes32 subnetwork,
        address operator,
        uint256, /* amount */
        uint48 /* captureTimestamp */
    ) external {
        address network = subnetwork.network();
        uint256 currentBalance = IERC20(collateral).balanceOf(address(this));
        balanceOf[_getReceiver(network, operator)] += currentBalance - lastBalance;
        lastBalance = currentBalance;
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function triggerTransfer(
        address receiver
    ) external returns (uint256 amount) {
        amount = balanceOf[receiver];

        if (amount == 0) {
            revert InsufficientBalance();
        }

        balanceOf[receiver] = 0;

        IERC20(collateral).safeTransfer(receiver, amount);

        emit TriggerTransfer(receiver, amount);
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function setGlobalReceiver(
        address receiver
    ) external onlyOwner {
        _setReceiver(receiver, globalReceiver, pendingGlobalReceiver);

        emit SetGlobalReceiver(receiver);
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function acceptGlobalReceiver() external {
        _acceptReceiver(globalReceiver, pendingGlobalReceiver);

        emit AcceptGlobalReceiver();
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function setNetworkReceiver(address network, address receiver) external onlyOwner {
        _setReceiver(receiver, networkReceiver[network], pendingNetworkReceiver[network]);

        emit SetNetworkReceiver(network, receiver);
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function acceptNetworkReceiver(
        address network
    ) external {
        _acceptReceiver(networkReceiver[network], pendingNetworkReceiver[network]);

        emit AcceptNetworkReceiver(network);
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function setOperatorNetworkReceiver(address network, address operator, address receiver) external onlyOwner {
        _setReceiver(
            receiver, operatorNetworkReceiver[network][operator], pendingOperatorNetworkReceiver[network][operator]
        );

        emit SetOperatorNetworkReceiver(network, operator, receiver);
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function acceptOperatorNetworkReceiver(address network, address operator) external {
        _acceptReceiver(operatorNetworkReceiver[network][operator], pendingOperatorNetworkReceiver[network][operator]);

        emit AcceptOperatorNetworkReceiver(network, operator);
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function setDelay(
        uint48 newDelay
    ) external {
        if (pendingDelay.timestamp != 0 && pendingDelay.timestamp <= Time.timestamp()) {
            delay.value = pendingDelay.value;
            pendingDelay.value = 0;
            pendingDelay.timestamp = 0;
        }

        if (pendingDelay.timestamp != 0) {
            pendingDelay.value = 0;
            pendingDelay.timestamp = 0;
        } else if (newDelay == delay.value) {
            revert AlreadySet();
        }

        if (newDelay != delay.value) {
            pendingDelay.value = newDelay;
            pendingDelay.timestamp = Time.timestamp() + delay.value;
        }
    }

    /**
     * @inheritdoc IBurnerRouter
     */
    function acceptDelay() external {
        if (pendingDelay.timestamp == 0 || pendingDelay.timestamp > Time.timestamp()) {
            revert NotReady();
        }

        delay.value = pendingDelay.value;
        pendingDelay.value = 0;
        pendingDelay.timestamp = 0;
    }

    function initialize(
        InitParams calldata params
    ) external initializer {
        if (params.collateral == address(0)) {
            revert InvalidCollateral();
        }

        if (params.owner != address(0)) {
            __Ownable_init(params.owner);
        }

        collateral = params.collateral;
        delay.value = params.delay;

        globalReceiver.value = params.globalReceiver;

        for (uint256 i; i < params.networkReceivers.length; ++i) {
            address network = params.networkReceivers[i].network;
            address receiver = params.networkReceivers[i].receiver;
            Address storage networkReceiver_ = networkReceiver[network];

            if (receiver == address(0)) {
                revert InvalidReceiver();
            }

            if (networkReceiver_.value != address(0)) {
                revert DuplicateNetworkReceiver();
            }

            networkReceiver_.value = receiver;
        }

        for (uint256 i; i < params.operatorNetworkReceivers.length; ++i) {
            address network = params.operatorNetworkReceivers[i].network;
            address operator = params.operatorNetworkReceivers[i].operator;
            address receiver = params.operatorNetworkReceivers[i].receiver;
            Address storage operatorNetworkReceiver_ = operatorNetworkReceiver[network][operator];

            if (receiver == address(0)) {
                revert InvalidReceiver();
            }

            if (operatorNetworkReceiver_.value != address(0)) {
                revert DuplicateOperatorNetworkReceiver();
            }

            operatorNetworkReceiver_.value = receiver;
        }
    }

    function _getReceiver(address network, address operator) internal view returns (address receiver) {
        address operatorNetworkReceiver_ = operatorNetworkReceiver[network][operator].value;
        if (operatorNetworkReceiver_ != address(0)) {
            return operatorNetworkReceiver_;
        }

        address networkReceiver_ = networkReceiver[network].value;
        if (networkReceiver_ != address(0)) {
            return networkReceiver_;
        }

        return globalReceiver.value;
    }

    function _setReceiver(
        address newReceiver,
        Address storage currentReceiver,
        PendingAddress storage pendingReceiver
    ) internal {
        if (pendingReceiver.timestamp != 0 && pendingReceiver.timestamp <= Time.timestamp()) {
            currentReceiver.value = pendingReceiver.value;
            pendingReceiver.value = address(0);
            pendingReceiver.timestamp = 0;
        }

        if (pendingReceiver.timestamp != 0) {
            pendingReceiver.value = address(0);
            pendingReceiver.timestamp = 0;
        } else if (newReceiver == currentReceiver.value) {
            revert AlreadySet();
        }

        if (newReceiver != currentReceiver.value) {
            pendingReceiver.value = newReceiver;
            pendingReceiver.timestamp = Time.timestamp() + delay.value;
        }
    }

    function _acceptReceiver(Address storage currentReceiver, PendingAddress storage pendingReceiver) internal {
        if (pendingReceiver.timestamp == 0 || pendingReceiver.timestamp > Time.timestamp()) {
            revert NotReady();
        }

        currentReceiver.value = pendingReceiver.value;
        pendingReceiver.value = address(0);
        pendingReceiver.timestamp = 0;
    }
}
