// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {DC_sUSDe_Miniburner} from "./DC_sUSDe_Miniburner.sol";
import {AddressRequests} from "src/contracts/AddressRequests.sol";

import {IDC_sUSDe_Burner} from "src/interfaces/burners/DC_sUSDe/IDC_sUSDe_Burner.sol";
import {ISUSDe} from "src/interfaces/burners/DC_sUSDe/ISUSDe.sol";
import {IUSDe} from "src/interfaces/burners/DC_sUSDe/IUSDe.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract DC_sUSDe_Burner is AddressRequests, IDC_sUSDe_Burner {
    using Clones for address;

    address private constant _DEAD = address(0xdEaD);

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    address public immutable USDE;

    address private immutable _MINIBURNER_IMPLEMENTATION;

    constructor(address collateral, address implementation) {
        COLLATERAL = collateral;

        USDE = ISUSDe(COLLATERAL).asset();

        _MINIBURNER_IMPLEMENTATION = implementation;
    }

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    function triggerWithdrawal() external returns (address requestId) {
        if (ISUSDe(COLLATERAL).cooldownDuration() == 0) {
            revert NoCooldown();
        }

        requestId = _MINIBURNER_IMPLEMENTATION.clone();

        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));
        IERC20(COLLATERAL).transfer(requestId, amount);

        DC_sUSDe_Miniburner(requestId).initialize(amount);

        _addRequestId(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc IDC_sUSDe_Burner
     */
    function triggerBurn(address requestId) external {
        _removeRequestId(requestId);

        DC_sUSDe_Miniburner(requestId).triggerBurn();

        emit TriggerBurn(msg.sender, requestId);
    }

    /**
     * @inheritdoc IDC_sUSDe_Burner
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
