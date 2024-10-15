// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IRouterBurnerConfigurator} from "../interfaces/IRouterBurnerConfigurator.sol";
import {IRouterBurnerFactory} from "../interfaces/router/IRouterBurnerFactory.sol";
import {IRouterBurner} from "../interfaces/router/IRouterBurner.sol";

import {IVaultConfigurator} from "@symbioticfi/core/src/interfaces/IVaultConfigurator.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {IVaultTokenized} from "@symbioticfi/core/src/interfaces/vault/IVaultTokenized.sol";

contract RouterBurnerConfigurator is IRouterBurnerConfigurator {
    /**
     * @inheritdoc IRouterBurnerConfigurator
     */
    address public immutable ROUTER_BURNER_FACTORY;

    /**
     * @inheritdoc IRouterBurnerConfigurator
     */
    address public immutable VAULT_CONFIGURATOR;

    constructor(address routerBurnerFactory, address vaultConfigurator) {
        ROUTER_BURNER_FACTORY = routerBurnerFactory;
        VAULT_CONFIGURATOR = vaultConfigurator;
    }

    /**
     * @inheritdoc IRouterBurnerConfigurator
     */
    function create(
        InitParams memory params
    ) external returns (address routerBurner, address vault, address delegator, address slasher) {
        routerBurner = IRouterBurnerFactory(ROUTER_BURNER_FACTORY).create(params.routerBurnerParams);

        if (params.vaultConfiguratorParams.version == 1) {
            IVault.InitParams memory vaultParams =
                abi.decode(params.vaultConfiguratorParams.vaultParams, (IVault.InitParams));

            if (vaultParams.burner != address(0)) {
                revert DirtyInitParams();
            }

            vaultParams.burner = address(routerBurner);
            params.vaultConfiguratorParams.vaultParams = abi.encode(vaultParams);
        } else if (params.vaultConfiguratorParams.version == 2) {
            IVaultTokenized.InitParamsTokenized memory vaultParams =
                abi.decode(params.vaultConfiguratorParams.vaultParams, (IVaultTokenized.InitParamsTokenized));

            if (vaultParams.baseParams.burner != address(0)) {
                revert DirtyInitParams();
            }

            vaultParams.baseParams.burner = address(routerBurner);
            params.vaultConfiguratorParams.vaultParams = abi.encode(vaultParams);
        } else {
            revert UnsupportedVersion();
        }

        (vault, delegator, slasher) = IVaultConfigurator(VAULT_CONFIGURATOR).create(params.vaultConfiguratorParams);

        IRouterBurner(routerBurner).setVault(vault);
    }
}
