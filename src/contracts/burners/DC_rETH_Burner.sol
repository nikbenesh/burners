// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";

import {IDC_rETH_Burner} from "src/interfaces/burners/DC_rETH/IDC_rETH_Burner.sol";
import {IRocketTokenRETH} from "src/interfaces/burners/DC_rETH/IRocketTokenRETH.sol";

contract DC_rETH_Burner is IDC_rETH_Burner {
    /**
     * @inheritdoc IDC_rETH_Burner
     */
    address public immutable COLLATERAL;

    constructor(address collateral) {
        COLLATERAL = collateral;
    }

    /**
     * @inheritdoc IDC_rETH_Burner
     */
    function triggerBurn(uint256 amount) external {
        IRocketTokenRETH(COLLATERAL).burn(amount);

        uint256 ethToBurn = address(this).balance;
        new SelfDestruct{value: ethToBurn}();

        emit TriggerBurn(msg.sender, amount, ethToBurn);
    }

    receive() external payable {}
}
