// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {mETH_Burner} from "../../src/contracts/burners/mETH_Burner.sol";

contract mETH_BurnerScript is Script {
    function run() public {
        vm.startBroadcast();

        address collateral;
        if (block.chainid == 1) {
            // mainnet
            collateral = 0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa;
        } else if (block.chainid == 17_000) {
            // holesky
            collateral = 0xe3C063B1BEe9de02eb28352b55D49D85514C67FF;
        } else if (block.chainid == 11_155_111) {
            // sepolia
            collateral = 0x072d71b257ECa6B60b5333626F6a55ea1B0c451c;
        } else {
            revert();
        }

        address mETH_BurnerAddress = address(new mETH_Burner(collateral));

        console2.log("mETH_Burner: ", mETH_BurnerAddress);

        vm.stopBroadcast();
    }
}
