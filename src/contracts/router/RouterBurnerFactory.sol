// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {RouterBurner} from "./RouterBurner.sol";

import {IRouterBurnerFactory} from "../../interfaces/router/IRouterBurnerFactory.sol";

import {Registry} from "@symbioticfi/core/src/contracts/common/Registry.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract RouterBurnerFactory is Registry, IRouterBurnerFactory {
    using Clones for address;

    address private immutable ROUTER_BURNER_IMPLEMENTATION;

    constructor(
        address routerBurnerImplementation
    ) {
        ROUTER_BURNER_IMPLEMENTATION = routerBurnerImplementation;
    }

    /**
     * @inheritdoc IRouterBurnerFactory
     */
    function create(
        RouterBurner.InitParams calldata params
    ) external returns (address) {
        address routerBurner =
            ROUTER_BURNER_IMPLEMENTATION.cloneDeterministic(keccak256(abi.encode(totalEntities(), params)));
        RouterBurner(routerBurner).initialize(params);

        _addEntity(routerBurner);

        return routerBurner;
    }
}
