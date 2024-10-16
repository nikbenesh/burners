// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBurner} from "@symbioticfi/core/src/interfaces/slasher/IBurner.sol";

interface IBurnerRouter is IBurner {
    error AlreadySet();
    error DuplicateNetworkReceiver();
    error DuplicateOperatorNetworkReceiver();
    error InsufficientBalance();
    error InvalidReceiverSetEpochsDelay();
    error InvalidReceiver();
    error InvalidCollateral();
    error NotReady();

    struct Address {
        address value;
    }

    struct PendingAddress {
        address value;
        uint48 timestamp;
    }

    struct Uint48 {
        uint48 value;
    }

    struct PendingUint48 {
        uint48 value;
        uint48 timestamp;
    }

    struct NetworkReceiver {
        address network;
        address receiver;
    }

    struct OperatorNetworkReceiver {
        address network;
        address operator;
        address receiver;
    }

    struct InitParams {
        address owner;
        address collateral;
        uint48 delay;
        address globalReceiver;
        NetworkReceiver[] networkReceivers;
        OperatorNetworkReceiver[] operatorNetworkReceivers;
    }

    event TriggerTransfer(address indexed receiver, uint256 amount);

    event SetGlobalReceiver(address receiver);

    event AcceptGlobalReceiver();

    event SetNetworkReceiver(address indexed network, address receiver);

    event AcceptNetworkReceiver(address indexed network);

    event SetOperatorNetworkReceiver(address indexed network, address indexed operator, address receiver);

    event AcceptOperatorNetworkReceiver(address indexed network, address indexed operator);

    function collateral() external view returns (address);

    function lastBalance() external view returns (uint256);

    function delay() external view returns (uint48);

    function pendingDelay() external view returns (uint48, uint48);

    function globalReceiver() external view returns (address);

    function pendingGlobalReceiver() external view returns (address, uint48);

    function networkReceiver(
        address network
    ) external view returns (address);

    function pendingNetworkReceiver(
        address network
    ) external view returns (address, uint48);

    function operatorNetworkReceiver(address network, address operator) external view returns (address);

    function pendingOperatorNetworkReceiver(
        address network,
        address operator
    ) external view returns (address, uint48);

    function balanceOf(
        address receiver
    ) external view returns (uint256);

    function triggerTransfer(
        address receiver
    ) external returns (uint256 amount);

    function setGlobalReceiver(
        address receiver
    ) external;

    function acceptGlobalReceiver() external;

    function setNetworkReceiver(address network, address receiver) external;

    function acceptNetworkReceiver(
        address network
    ) external;

    function setOperatorNetworkReceiver(address network, address operator, address receiver) external;

    function acceptOperatorNetworkReceiver(address network, address operator) external;

    function setDelay(
        uint48 newDelay
    ) external;

    function acceptDelay() external;
}
