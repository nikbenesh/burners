// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {BurnerRouterFactory} from "../../src/contracts/router/BurnerRouterFactory.sol";
import {BurnerRouter} from "../../src/contracts/router/BurnerRouter.sol";

contract BurnerRouterFactoryScript is Script {
    function run() public {
        vm.startBroadcast();

        address burnerRouterImplementation = address(new BurnerRouter());
        address burnerRouterFactory = address(new BurnerRouterFactory(burnerRouterImplementation));

        console2.log("Burner Router Factory: ", burnerRouterFactory);

        vm.stopBroadcast();
    }
}
