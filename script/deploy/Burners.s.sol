// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {BurnerRouterFactory} from "../../src/contracts/router/BurnerRouterFactory.sol";
import {BurnerRouter} from "../../src/contracts/router/BurnerRouter.sol";

import {wstETH_Burner} from "../../src/contracts/burners/wstETH_Burner.sol";
import {rETH_Burner} from "../../src/contracts/burners/rETH_Burner.sol";
import {mETH_Burner} from "../../src/contracts/burners/mETH_Burner.sol";
import {swETH_Burner} from "../../src/contracts/burners/swETH_Burner.sol";
import {sfrxETH_Burner} from "../../src/contracts/burners/sfrxETH_Burner.sol";
import {ETHx_Burner} from "../../src/contracts/burners/ETHx_Burner.sol";

contract BurnersScript is Script {
    function run() public {
        vm.startBroadcast();

        address burnerRouterFactory;
        {
            address burnerRouterImplementation = address(new BurnerRouter());
            burnerRouterFactory = address(new BurnerRouterFactory(burnerRouterImplementation));
        }

        bool deploy_wstETH_Burner = block.chainid == 1 || block.chainid == 17_000 || block.chainid == 11_155_111;
        address wstETH_BurnerAddress;
        if (deploy_wstETH_Burner) {
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
            }

            wstETH_BurnerAddress = address(new wstETH_Burner(collateral, lidoWithdrawalQueue));
        }

        bool deploy_rETH_Burner = block.chainid == 1 || block.chainid == 17_000;
        address rETH_BurnerAddress;
        if (deploy_rETH_Burner) {
            address collateral;
            if (block.chainid == 1) {
                // mainnet
                collateral = 0xae78736Cd615f374D3085123A210448E74Fc6393;
            } else if (block.chainid == 17_000) {
                // holesky
                collateral = 0x7322c24752f79c05FFD1E2a6FCB97020C1C264F1;
            }

            rETH_BurnerAddress = address(new rETH_Burner(collateral));
        }

        bool deploy_mETH_Burner = block.chainid == 1 || block.chainid == 17_000 || block.chainid == 11_155_111;
        address mETH_BurnerAddress;
        if (deploy_mETH_Burner) {
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
            }

            mETH_BurnerAddress = address(new mETH_Burner(collateral));
        }

        bool deploy_swETH_Burner = block.chainid == 1;
        address swETH_BurnerAddress;
        if (deploy_swETH_Burner) {
            address collateral;
            address swEXIT;
            if (block.chainid == 1) {
                // mainnet
                collateral = 0xf951E335afb289353dc249e82926178EaC7DEd78;
                swEXIT = 0x48C11b86807627AF70a34662D4865cF854251663;
            }

            swETH_BurnerAddress = address(new swETH_Burner(collateral, swEXIT));
        }

        bool deploy_sfrxETH_Burner = block.chainid == 1;
        address sfrxETH_BurnerAddress;
        if (deploy_sfrxETH_Burner) {
            address collateral;
            address fraxEtherRedemptionQueue;
            if (block.chainid == 1) {
                // mainnet
                collateral = 0xac3E018457B222d93114458476f3E3416Abbe38F;
                fraxEtherRedemptionQueue = 0x82bA8da44Cd5261762e629dd5c605b17715727bd;
            }

            sfrxETH_BurnerAddress = address(new sfrxETH_Burner(collateral, fraxEtherRedemptionQueue));
        }

        bool deploy_ETHx_Burner = block.chainid == 1 || block.chainid == 17_000;
        address ETHx_BurnerAddress;
        if (deploy_ETHx_Burner) {
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
            }

            ETHx_BurnerAddress = address(new ETHx_Burner(collateral, staderConfig));
        }

        console2.log("Burner Router Factory: ", burnerRouterFactory);
        if (deploy_wstETH_Burner) {
            console2.log("wstETH_Burner: ", wstETH_BurnerAddress);
        }
        if (deploy_rETH_Burner) {
            console2.log("rETH_Burner: ", rETH_BurnerAddress);
        }
        if (deploy_mETH_Burner) {
            console2.log("mETH_Burner: ", mETH_BurnerAddress);
        }
        if (deploy_swETH_Burner) {
            console2.log("swETH_Burner: ", swETH_BurnerAddress);
        }
        if (deploy_sfrxETH_Burner) {
            console2.log("sfrxETH_Burner: ", sfrxETH_BurnerAddress);
        }
        if (deploy_ETHx_Burner) {
            console2.log("ETHx_Burner: ", ETHx_BurnerAddress);
        }

        vm.stopBroadcast();
    }
}
