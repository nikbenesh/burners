// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {AddressRequests} from "src/contracts/AddressRequests.sol";
import {sUSDe_Miniburner} from "./sUSDe_Miniburner.sol";

import {ISUSDe} from "src/interfaces/burners/sUSDe/ISUSDe.sol";
import {IUSDe} from "src/interfaces/burners/sUSDe/IUSDe.sol";
import {IsUSDe_Burner} from "src/interfaces/burners/sUSDe/IsUSDe_Burner.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract sUSDe_Burner is AddressRequests, IsUSDe_Burner {
    using Clones for address;

    address private constant _DEAD = address(0xdEaD);

    /**
     * @inheritdoc IsUSDe_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IsUSDe_Burner
     */
    address public immutable USDE;

    address private immutable _MINIBURNER_IMPLEMENTATION;

    constructor(address collateral, address implementation) {
        COLLATERAL = collateral;

        USDE = ISUSDe(COLLATERAL).asset();

        _MINIBURNER_IMPLEMENTATION = implementation;
    }

    /**
     * @inheritdoc IsUSDe_Burner
     */
    function triggerWithdrawal() external returns (address requestId) {
        if (ISUSDe(COLLATERAL).cooldownDuration() == 0) {
            revert NoCooldown();
        }

        requestId = _MINIBURNER_IMPLEMENTATION.clone();

        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));
        IERC20(COLLATERAL).transfer(requestId, amount);

        sUSDe_Miniburner(requestId).initialize(amount);

        _addRequestId(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc IsUSDe_Burner
     */
    function triggerBurn(address requestId) external {
        _removeRequestId(requestId);

        sUSDe_Miniburner(requestId).triggerBurn();

        emit TriggerBurn(msg.sender, requestId);
    }

    /**
     * @inheritdoc IsUSDe_Burner
     */
    function triggerInstantBurn() external {
        if (ISUSDe(COLLATERAL).cooldownDuration() != 0) {
            revert HasCooldown();
        }

        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));

        IUSDe(USDE).burn(ISUSDe(COLLATERAL).redeem(amount, address(this), address(this)));

        emit TriggerInstantBurn(msg.sender, amount);
    }
}
