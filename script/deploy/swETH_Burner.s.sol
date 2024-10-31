// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {swETH_Burner} from "../../src/contracts/burners/swETH_Burner.sol";

contract swETH_BurnerScript is Script {
    function run() public {
        vm.startBroadcast();

        address collateral;
        address swEXIT;
        if (block.chainid == 1) {
            // mainnet
            collateral = 0xf951E335afb289353dc249e82926178EaC7DEd78;
            swEXIT = 0x48C11b86807627AF70a34662D4865cF854251663;
        } else {
            revert();
        }

        address swETH_BurnerAddress = address(new swETH_Burner(collateral, swEXIT));

        console2.log("swETH_Burner: ", swETH_BurnerAddress);

        vm.stopBroadcast();
    }
}
