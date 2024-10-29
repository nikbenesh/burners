// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {wstETH_Burner} from "../../src/contracts/burners/wstETH_Burner.sol";

contract wstETH_BurnerScript is Script {
    function run() public {
        vm.startBroadcast();

        address collateral;
        address lidoWithdrawalQueue;
        if (block.chainid == 1) {
            // mainnet
            collateral = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
            lidoWithdrawalQueue = 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;
        } else if (block.chainid == 17_000) {
            // holesky
            collateral = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
            lidoWithdrawalQueue = 0xc7cc160b58F8Bb0baC94b80847E2CF2800565C50;
        } else if (block.chainid == 11_155_111) {
            // sepolia
            collateral = 0xB82381A3fBD3FaFA77B3a7bE693342618240067b;
            lidoWithdrawalQueue = 0x1583C7b3f4C3B008720E6BcE5726336b0aB25fdd;
        } else {
            revert();
        }

        address wstETH_BurnerAddress = address(new wstETH_Burner(collateral, lidoWithdrawalQueue));

        console2.log("wstETH_Burner: ", wstETH_BurnerAddress);

        vm.stopBroadcast();
    }
}
