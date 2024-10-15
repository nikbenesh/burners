// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterBurner} from "./IRouterBurner.sol";

interface IRouterBurnerFactory {
    /**
     * @notice Create a router burner contract.
     * @param params initial parameters needed for a router burner contract deployment
     * @return address of the created router burner contract
     */
    function create(
        IRouterBurner.InitParams calldata params
    ) external returns (address);
}
