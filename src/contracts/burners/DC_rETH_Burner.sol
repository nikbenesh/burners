// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";

import {IDC_rETH_Burner} from "src/interfaces/burners/DC_rETH/IDC_rETH_Burner.sol";
import {IRocketTokenRETH} from "src/interfaces/burners/DC_rETH/IRocketTokenRETH.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";

contract DC_rETH_Burner is IDC_rETH_Burner {
    /**
     * @inheritdoc IDC_rETH_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IDC_rETH_Burner
     */
    address public immutable ASSET;

    constructor(address collateral) {
        COLLATERAL = collateral;

        ASSET = IDefaultCollateral(collateral).asset();
    }

    /**
     * @inheritdoc IDC_rETH_Burner
     */
    function triggerBurn(uint256 amount) external {
        if (amount == 0) {
            revert InsufficientBurn();
        }

        IDefaultCollateral(COLLATERAL).withdraw(address(this), amount);

        IRocketTokenRETH(ASSET).burn(amount);

        emit TriggerBurn(msg.sender, amount, address(this).balance);

        new SelfDestruct{value: address(this).balance}();
    }

    receive() external payable {}
}
