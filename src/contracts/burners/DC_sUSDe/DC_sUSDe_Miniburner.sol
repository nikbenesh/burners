// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ISUSDe} from "src/interfaces/burners/DC_sUSDe/ISUSDe.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DC_sUSDe_Miniburner is OwnableUpgradeable {
    address private constant _DEAD = address(0xdEaD);

    address private immutable _ASSET;

    constructor(address asset) {
        _ASSET = asset;
    }

    function initialize(uint256 amount) external initializer {
        __Ownable_init(msg.sender);

        if (ISUSDe(_ASSET).cooldownDuration() != 0) {
            ISUSDe(_ASSET).redeem(amount, address(this), address(this));
        } else {
            ISUSDe(_ASSET).cooldownShares(amount);
        }
    }

    function triggerBurn() external onlyOwner {
        ISUSDe(_ASSET).unstake(_DEAD);
    }
}
