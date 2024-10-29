// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {rETH_Burner} from "../../src/contracts/burners/rETH_Burner.sol";

contract rETH_BurnerScript is Script {
    function run() public {
        vm.startBroadcast();

        address collateral;
        if (block.chainid == 1) {
            // mainnet
            collateral = 0xae78736Cd615f374D3085123A210448E74Fc6393;
        } else if (block.chainid == 17_000) {
            // holesky
            collateral = 0x7322c24752f79c05FFD1E2a6FCB97020C1C264F1;
        } else {
            revert();
        }

        address rETH_BurnerAddress = address(new rETH_Burner(collateral));

        console2.log("rETH_Burner: ", rETH_BurnerAddress);

        vm.stopBroadcast();
    }
}
