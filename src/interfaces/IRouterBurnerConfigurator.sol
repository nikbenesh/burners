// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IRouterBurner} from "./router/IRouterBurner.sol";

import {IVaultConfigurator} from "@symbioticfi/core/src/interfaces/IVaultConfigurator.sol";

interface IRouterBurnerConfigurator {
    error DirtyInitParams();
    error UnsupportedVersion();

    /**
     * @notice Initial parameters needed for a set of vault contracts with a router burner deployment.
     * @param routerBurnerParams initial parameters for the router burner deployment
     * @param vaultConfiguratorParams initial parameters for the vault contracts deployment
     */
    struct InitParams {
        IRouterBurner.InitParams routerBurnerParams;
        IVaultConfigurator.InitParams vaultConfiguratorParams;
    }

    /**
     * @notice Get the router burner factory's address.
     * @return address of the router burner factory
     */
    function ROUTER_BURNER_FACTORY() external view returns (address);

    /**
     * @notice Get the vault configurator's address.
     * @return address of the vault configurator
     */
    function VAULT_CONFIGURATOR() external view returns (address);

    /**
     * @notice Create a new set of vault contracts with a router burner.
     * @param params initial parameters needed for a set of vault contracts with a router burner deployment
     * @return routerBurner address of the router burner
     * @return vault address of the vault
     * @return delegator address of the delegator
     * @return slasher address of the slasher
     */
    function create(
        InitParams memory params
    ) external returns (address routerBurner, address vault, address delegator, address slasher);
}
