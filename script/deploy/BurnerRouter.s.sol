// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {IBurnerRouterFactory} from "../../src/interfaces/router/IBurnerRouterFactory.sol";
import {IBurnerRouter} from "../../src/interfaces/router/IBurnerRouter.sol";

contract BurnerRouterScript is Script {
    function run(
        address burnerRouterFactory,
        address owner,
        address collateral,
        uint48 delay,
        address globalReceiver,
        IBurnerRouter.NetworkReceiver[] calldata networkReceivers,
        IBurnerRouter.OperatorNetworkReceiver[] calldata operatorNetworkReceivers
    ) public {
        vm.startBroadcast();

        address burnerRouter = IBurnerRouterFactory(burnerRouterFactory).create(
            IBurnerRouter.InitParams({
                owner: owner,
                collateral: collateral,
                delay: delay,
                globalReceiver: globalReceiver,
                networkReceivers: networkReceivers,
                operatorNetworkReceivers: operatorNetworkReceivers
            })
        );

        console2.log("Burner Router: ", burnerRouter);

        vm.stopBroadcast();
    }
}
