// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ISUSDe} from "src/interfaces/burners/DC_sUSDe/ISUSDe.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DC_sUSDe_Miniburner is OwnableUpgradeable {
    address private constant _DEAD = address(0xdEaD);

    address private immutable _ASSET;

    constructor(address asset) {
        _disableInitializers();

        _ASSET = asset;
    }

    function initialize(uint256 amount) external initializer {
        __Ownable_init(msg.sender);

        ISUSDe(_ASSET).cooldownShares(amount);
    }

    function triggerBurn() external onlyOwner {
        ISUSDe(_ASSET).unstake(_DEAD);
    }
}
