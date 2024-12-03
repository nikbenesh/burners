// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BurnerRouter as SymbioticBurnerRouter} from "../../src/contracts/router/BurnerRouter.sol";
import {BurnerRouterFactory as SymbioticBurnerRouterFactory} from "../../src/contracts/router/BurnerRouterFactory.sol";
import {AddressRequests as SymbioticAddressRequests} from "../../src/contracts/common/AddressRequests.sol";
import {UintRequests as SymbioticUintRequests} from "../../src/contracts/common/UintRequests.sol";
import {SelfDestruct as SymbioticSelfDestruct} from "../../src/contracts/common/SelfDestruct.sol";
import {ETHx_Burner as SymbioticETHx_Burner} from "../../src/contracts/burners/ETHx_Burner.sol";
import {mETH_Burner as SymbioticmETH_Burner} from "../../src/contracts/burners/mETH_Burner.sol";
import {rETH_Burner as SymbioticrETH_Burner} from "../../src/contracts/burners/rETH_Burner.sol";
import {sfrxETH_Burner as SymbioticsfrxETH_Burner} from "../../src/contracts/burners/sfrxETH_Burner.sol";
import {
    sUSDe_Burner as SymbioticsUSDe_Burner,
    sUSDe_Miniburner as SymbioticsUSDe_Miniburner
} from "../../src/contracts/burners/sUSDe/sUSDe_Burner.sol";
import {swETH_Burner as SymbioticswETH_Burner} from "../../src/contracts/burners/swETH_Burner.sol";
import {wstETH_Burner as SymbioticwstETH_Burner} from "../../src/contracts/burners/wstETH_Burner.sol";

interface SymbioticBurnersImportsContracts {}
