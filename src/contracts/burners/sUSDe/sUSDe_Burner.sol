// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {AddressRequests} from "../../AddressRequests.sol";
import {SelfDestruct} from "../../SelfDestruct.sol";
import {sUSDe_Miniburner} from "./sUSDe_Miniburner.sol";

import {IEthenaMinting} from "../../../interfaces/burners/sUSDe/IEthenaMinting.sol";
import {ISUSDe} from "../../../interfaces/burners/sUSDe/ISUSDe.sol";
import {IUSDe} from "../../../interfaces/burners/sUSDe/IUSDe.sol";
import {IsUSDe_Burner} from "../../../interfaces/burners/sUSDe/IsUSDe_Burner.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract sUSDe_Burner is AddressRequests, IERC1271, IsUSDe_Burner {
    using Clones for address;
    using SafeERC20 for IERC20;

    address private constant _DEAD = address(0xdEaD);

    bytes4 private constant _MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    /**
     * @inheritdoc IsUSDe_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IsUSDe_Burner
     */
    address public immutable USDE;

    address private immutable _MINIBURNER_IMPLEMENTATION;

    constructor(address collateral, address miniburnerImplementation) {
        COLLATERAL = collateral;

        USDE = ISUSDe(COLLATERAL).asset();

        _MINIBURNER_IMPLEMENTATION = miniburnerImplementation;

        IERC20(USDE).forceApprove(IUSDe(USDE).minter(), type(uint256).max);
    }

    /**
     * @inheritdoc IERC1271
     */
    function isValidSignature(bytes32 hash_, bytes memory signature) external view returns (bytes4) {
        IEthenaMinting.Order memory order = abi.decode(signature, (IEthenaMinting.Order));

        if (hash_ == IEthenaMinting(IUSDe(USDE).minter()).hashOrder(order) && order.beneficiary == address(this)) {
            return _MAGICVALUE;
        }
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

        emit TriggerWithdrawal(msg.sender, amount, requestId);
    }

    /**
     * @inheritdoc IsUSDe_Burner
     */
    function triggerClaim(
        address requestId
    ) external {
        _removeRequestId(requestId);

        sUSDe_Miniburner(requestId).triggerClaim();

        emit TriggerClaim(msg.sender, requestId);
    }

    /**
     * @inheritdoc IsUSDe_Burner
     */
    function triggerInstantClaim() external {
        if (ISUSDe(COLLATERAL).cooldownDuration() != 0) {
            revert HasCooldown();
        }

        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));

        ISUSDe(COLLATERAL).redeem(amount, address(this), address(this));

        emit TriggerInstantClaim(msg.sender, amount);
    }

    /**
     * @inheritdoc IsUSDe_Burner
     */
    function triggerBurn(
        address asset
    ) external {
        if (asset == COLLATERAL || asset == USDE) {
            revert InvalidAsset();
        }

        uint256 amount;
        if (asset == address(0)) {
            amount = address(this).balance;
            new SelfDestruct{value: amount}();
        } else {
            amount = IERC20(asset).balanceOf(address(this));
            IERC20(asset).safeTransfer(_DEAD, amount);
        }

        emit TriggerBurn(msg.sender, asset, amount);
    }

    /**
     * @inheritdoc IsUSDe_Burner
     */
    function approveUSDeMinter() external {
        address minter = IUSDe(USDE).minter();
        if (IERC20(USDE).allowance(address(this), minter) == type(uint256).max) {
            revert SufficientApproval();
        }
        IERC20(USDE).forceApprove(minter, type(uint256).max);
    }
}
