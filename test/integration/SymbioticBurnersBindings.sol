// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SymbioticBurnersImports.sol";

import {Test} from "forge-std/Test.sol";

contract SymbioticBurnersBindings is Test {
    function _createBurnerRouter_SymbioticBurners(
        ISymbioticBurnerRouterFactory symbioticBurnerRouterFactory,
        address who,
        address owner,
        address collateral,
        uint48 delay,
        address globalReceiver,
        ISymbioticBurnerRouter.NetworkReceiver[] memory networkReceivers,
        ISymbioticBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers
    ) internal virtual returns (address burnerRouter) {
        vm.startPrank(who);
        burnerRouter = symbioticBurnerRouterFactory.create(
            ISymbioticBurnerRouter.InitParams({
                owner: owner,
                collateral: collateral,
                delay: delay,
                globalReceiver: globalReceiver,
                networkReceivers: networkReceivers,
                operatorNetworkReceivers: operatorNetworkReceivers
            })
        );
        vm.stopPrank();
    }

    function _triggerTransfer_SymbioticBurners(address who, address burnerRouter, address receiver) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).triggerTransfer(receiver);
        vm.stopPrank();
    }

    function _setGlobalReceiver_SymbioticBurners(
        address who,
        address burnerRouter,
        address receiver
    ) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).setGlobalReceiver(receiver);
        vm.stopPrank();
    }

    function _acceptGlobalReceiver_SymbioticBurners(address who, address burnerRouter) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).acceptGlobalReceiver();
        vm.stopPrank();
    }

    function _setNetworkReceiver_SymbioticBurners(
        address who,
        address burnerRouter,
        address network,
        address receiver
    ) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).setNetworkReceiver(network, receiver);
        vm.stopPrank();
    }

    function _acceptNetworkReceiver_SymbioticBurners(
        address who,
        address burnerRouter,
        address network
    ) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).acceptNetworkReceiver(network);
        vm.stopPrank();
    }

    function _setOperatorNetworkReceiver_SymbioticBurners(
        address who,
        address burnerRouter,
        address network,
        address operator,
        address receiver
    ) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).setOperatorNetworkReceiver(network, operator, receiver);
        vm.stopPrank();
    }

    function _acceptOperatorNetworkReceiver_SymbioticBurners(
        address who,
        address burnerRouter,
        address network,
        address operator
    ) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).acceptOperatorNetworkReceiver(network, operator);
        vm.stopPrank();
    }

    function _setDelay_SymbioticBurners(address who, address burnerRouter, uint48 newDelay) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).setDelay(newDelay);
        vm.stopPrank();
    }

    function _acceptDelay_SymbioticBurners(address who, address burnerRouter) internal virtual {
        vm.startPrank(who);
        ISymbioticBurnerRouter(burnerRouter).acceptDelay();
        vm.stopPrank();
    }

    function _triggerWithdrawal_ETHx_SymbioticBurners(
        address who,
        address burner,
        uint256 maxWithdrawalAmount
    ) internal virtual returns (uint256 requestId) {
        vm.startPrank(who);
        requestId = ISymbioticETHx_Burner(burner).triggerWithdrawal(maxWithdrawalAmount);
        vm.stopPrank();
    }

    function _triggerBurn_ETHx_SymbioticBurners(address who, address burner, uint256 requestId) internal virtual {
        vm.startPrank(who);
        ISymbioticETHx_Burner(burner).triggerBurn(requestId);
        vm.stopPrank();
    }

    function _triggerWithdrawal_mETH_SymbioticBurners(
        address who,
        address burner
    ) internal virtual returns (uint256 requestId) {
        vm.startPrank(who);
        requestId = ISymbioticmETH_Burner(burner).triggerWithdrawal();
        vm.stopPrank();
    }

    function _triggerBurn_mETH_SymbioticBurners(address who, address burner, uint256 requestId) internal virtual {
        vm.startPrank(who);
        ISymbioticmETH_Burner(burner).triggerBurn(requestId);
        vm.stopPrank();
    }

    function _triggerBurn_rETH_SymbioticBurners(address who, address burner, uint256 amount) internal virtual {
        vm.startPrank(who);
        ISymbioticrETH_Burner(burner).triggerBurn(amount);
        vm.stopPrank();
    }

    function _triggerWithdrawal_sfrxETH_SymbioticBurners(
        address who,
        address burner
    ) internal virtual returns (uint256 requestId) {
        vm.startPrank(who);
        requestId = ISymbioticsfrxETH_Burner(burner).triggerWithdrawal();
        vm.stopPrank();
    }

    function _triggerBurn_sfrxETH_SymbioticBurners(address who, address burner, uint256 requestId) internal virtual {
        vm.startPrank(who);
        ISymbioticsfrxETH_Burner(burner).triggerBurn(requestId);
        vm.stopPrank();
    }

    function _triggerWithdrawal_sUSDe_SymbioticBurners(
        address who,
        address burner
    ) internal virtual returns (address requestId) {
        vm.startPrank(who);
        requestId = ISymbioticsUSDe_Burner(burner).triggerWithdrawal();
        vm.stopPrank();
    }

    function _triggerClaim_sUSDe_SymbioticBurners(address who, address burner, address requestId) internal virtual {
        vm.startPrank(who);
        ISymbioticsUSDe_Burner(burner).triggerClaim(requestId);
        vm.stopPrank();
    }

    function _triggerInstantClaim_sUSDe_SymbioticBurners(address who, address burner) internal virtual {
        vm.startPrank(who);
        ISymbioticsUSDe_Burner(burner).triggerInstantClaim();
        vm.stopPrank();
    }

    function _triggerBurn_sUSDe_SymbioticBurners(address who, address burner, address asset) internal virtual {
        vm.startPrank(who);
        ISymbioticsUSDe_Burner(burner).triggerBurn(asset);
        vm.stopPrank();
    }

    function _approveUSDeMinter_sUSDe_SymbioticBurners(address who, address burner) internal virtual {
        vm.startPrank(who);
        ISymbioticsUSDe_Burner(burner).approveUSDeMinter();
        vm.stopPrank();
    }

    function _triggerWithdrawal_swETH_SymbioticBurners(
        address who,
        address burner,
        uint256 maxRequests
    ) internal virtual returns (uint256 firstRequestId, uint256 lastRequestId) {
        vm.startPrank(who);
        (firstRequestId, lastRequestId) = ISymbioticswETH_Burner(burner).triggerWithdrawal(maxRequests);
        vm.stopPrank();
    }

    function _triggerBurn_swETH_SymbioticBurners(address who, address burner, uint256 requestId) internal virtual {
        vm.startPrank(who);
        ISymbioticswETH_Burner(burner).triggerBurn(requestId);
        vm.stopPrank();
    }

    function _triggerWithdrawal_wstETH_SymbioticBurners(
        address who,
        address burner,
        uint256 maxRequests
    ) internal virtual returns (uint256[] memory requestIds) {
        vm.startPrank(who);
        requestIds = ISymbioticwstETH_Burner(burner).triggerWithdrawal(maxRequests);
        vm.stopPrank();
    }

    function _triggerBurn_wstETH_SymbioticBurners(address who, address burner, uint256 requestId) internal virtual {
        vm.startPrank(who);
        ISymbioticwstETH_Burner(burner).triggerBurn(requestId);
        vm.stopPrank();
    }

    function _triggerBurnBatch_wstETH_SymbioticBurners(
        address who,
        address burner,
        uint256[] memory requestIds,
        uint256[] memory hints
    ) internal virtual {
        vm.startPrank(who);
        ISymbioticwstETH_Burner(burner).triggerBurnBatch(requestIds, hints);
        vm.stopPrank();
    }
}
