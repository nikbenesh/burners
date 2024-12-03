// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBurnerRouter as ISymbioticBurnerRouter} from "../../src/interfaces/router/IBurnerRouter.sol";
import {IBurnerRouterFactory as ISymbioticBurnerRouterFactory} from
    "../../src/interfaces/router/IBurnerRouterFactory.sol";
import {IAddressRequests as ISymbioticAddressRequests} from "../../src/interfaces/common/IAddressRequests.sol";
import {IUintRequests as ISymbioticUintRequests} from "../../src/interfaces/common/IUintRequests.sol";
import {IETHx_Burner as ISymbioticETHx_Burner} from "../../src/interfaces/burners/ETHx/IETHx_Burner.sol";
import {ImETH_Burner as ISymbioticmETH_Burner} from "../../src/interfaces/burners/mETH/ImETH_Burner.sol";
import {IrETH_Burner as ISymbioticrETH_Burner} from "../../src/interfaces/burners/rETH/IrETH_Burner.sol";
import {IsfrxETH_Burner as ISymbioticsfrxETH_Burner} from "../../src/interfaces/burners/sfrxETH/IsfrxETH_Burner.sol";
import {IsUSDe_Burner as ISymbioticsUSDe_Burner} from "../../src/interfaces/burners/sUSDe/IsUSDe_Burner.sol";
import {IswETH_Burner as ISymbioticswETH_Burner} from "../../src/interfaces/burners/swETH/IswETH_Burner.sol";
import {IwstETH_Burner as ISymbioticwstETH_Burner} from "../../src/interfaces/burners/wstETH/IwstETH_Burner.sol";

interface SymbioticBurnersImports {}
