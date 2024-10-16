// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BurnerRouter} from "./BurnerRouter.sol";

import {IBurnerRouterFactory} from "../../interfaces/router/IBurnerRouterFactory.sol";

import {Registry} from "@symbioticfi/core/src/contracts/common/Registry.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract BurnerRouterFactory is Registry, IBurnerRouterFactory {
    using Clones for address;

    address private immutable BURNER_ROUTER_IMPLEMENTATION;

    constructor(
        address burnerRouterImplementation
    ) {
        BURNER_ROUTER_IMPLEMENTATION = burnerRouterImplementation;
    }

    /**
     * @inheritdoc IBurnerRouterFactory
     */
    function create(
        BurnerRouter.InitParams calldata params
    ) external returns (address) {
        address burnerRouter =
            BURNER_ROUTER_IMPLEMENTATION.cloneDeterministic(keccak256(abi.encode(totalEntities(), params)));
        BurnerRouter(burnerRouter).initialize(params);

        _addEntity(burnerRouter);

        return burnerRouter;
    }
}
