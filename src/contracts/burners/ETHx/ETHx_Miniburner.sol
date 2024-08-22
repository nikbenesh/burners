// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";

import {IStaderConfig} from "src/interfaces/burners/ETHx/IStaderConfig.sol";
import {IUserWithdrawalManager} from "src/interfaces/burners/ETHx/IUserWithdrawalManager.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ETHx_Miniburner is OwnableUpgradeable {
    address private immutable _COLLATERAL;

    address private immutable _USER_WITHDRAW_MANAGER;

    constructor(address collateral, address staderConfig) {
        _disableInitializers();

        _COLLATERAL = collateral;

        _USER_WITHDRAW_MANAGER = IStaderConfig(staderConfig).getUserWithdrawManager();
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
    }

    function triggerBurn(uint256 requestId) external onlyOwner {
        IUserWithdrawalManager(_USER_WITHDRAW_MANAGER).claim(requestId);

        new SelfDestruct{value: address(this).balance}();
    }

    receive() external payable {}
}
