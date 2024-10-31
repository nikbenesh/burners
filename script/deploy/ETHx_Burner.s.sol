// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {ETHx_Burner} from "../../src/contracts/burners/ETHx_Burner.sol";

contract ETHx_BurnerScript is Script {
    function run() public {
        vm.startBroadcast();

        address collateral;
        address staderConfig;
        if (block.chainid == 1) {
            // mainnet
            collateral = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;
            staderConfig = 0x4ABEF2263d5A5ED582FC9A9789a41D85b68d69DB;
        } else if (block.chainid == 17_000) {
            // holesky
            collateral = 0xB4F5fc289a778B80392b86fa70A7111E5bE0F859;
            staderConfig = 0x50FD3384783EE49011E7b57d7A3430a762b3f3F2;
        } else {
            revert();
        }

        address ETHx_BurnerAddress = address(new ETHx_Burner(collateral, staderConfig));

        console2.log("ETHx_Burner: ", ETHx_BurnerAddress);

        vm.stopBroadcast();
    }
}
