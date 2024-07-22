// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ISUSDe} from "src/interfaces/burners/DC_sUSDe/ISUSDe.sol";
import {IUSDe} from "src/interfaces/burners/DC_sUSDe/IUSDe.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DC_sUSDe_Miniburner is OwnableUpgradeable {
    address private constant _DEAD = address(0xdEaD);

    address private immutable _ASSET;

    address private immutable _USDE;

    constructor(address asset) {
        _disableInitializers();

        _ASSET = asset;
        _USDE = ISUSDe(asset).asset();
    }

    function initialize(uint256 amount) external initializer {
        __Ownable_init(msg.sender);

        ISUSDe(_ASSET).cooldownShares(amount);
    }

    function triggerBurn() external onlyOwner {
        ISUSDe(_ASSET).unstake(address(this));
        IUSDe(_USDE).burn(IERC20(_USDE).balanceOf(address(this)));
    }
}
