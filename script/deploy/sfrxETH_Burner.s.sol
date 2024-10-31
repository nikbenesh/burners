// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {sfrxETH_Burner} from "../../src/contracts/burners/sfrxETH_Burner.sol";

contract sfrxETH_BurnerScript is Script {
    function run() public {
        vm.startBroadcast();

        address collateral;
        address fraxEtherRedemptionQueue;
        if (block.chainid == 1) {
            // mainnet
            collateral = 0xac3E018457B222d93114458476f3E3416Abbe38F;
            fraxEtherRedemptionQueue = 0x82bA8da44Cd5261762e629dd5c605b17715727bd;
        } else {
            revert();
        }

        address sfrxETH_BurnerAddress = address(new sfrxETH_Burner(collateral, fraxEtherRedemptionQueue));

        console2.log("sfrxETH_Burner: ", sfrxETH_BurnerAddress);

        vm.stopBroadcast();
    }
}
