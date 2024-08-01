// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ISUSDe} from "src/interfaces/burners/sUSDe/ISUSDe.sol";
import {IUSDe} from "src/interfaces/burners/sUSDe/IUSDe.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract sUSDe_Miniburner is OwnableUpgradeable {
    address private constant _DEAD = address(0xdEaD);

    address private immutable _COLLATERAL;

    address private immutable _USDE;

    constructor(address collateral) {
        _disableInitializers();

        _COLLATERAL = collateral;
        _USDE = ISUSDe(collateral).asset();
    }

    function initialize(uint256 amount) external initializer {
        __Ownable_init(msg.sender);

        ISUSDe(_COLLATERAL).cooldownShares(amount);
    }

    function triggerBurn() external onlyOwner {
        ISUSDe(_COLLATERAL).unstake(address(this));
        IUSDe(_USDE).burn(IERC20(_USDE).balanceOf(address(this)));
    }
}
