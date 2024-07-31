// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";
import {UintRequests} from "src/contracts/UintRequests.sol";

import {ImETH_Burner} from "src/interfaces/burners/mETH/ImETH_Burner.sol";
import {IStaking} from "src/interfaces/burners/mETH/IStaking.sol";
import {IMETH} from "src/interfaces/burners/mETH/IMETH.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract mETH_Burner is UintRequests, ImETH_Burner {
    /**
     * @inheritdoc ImETH_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc ImETH_Burner
     */
    address public immutable STAKING;

    constructor(address collateral) {
        COLLATERAL = collateral;

        STAKING = IMETH(COLLATERAL).stakingContract();

        IERC20(COLLATERAL).approve(STAKING, type(uint256).max);
    }

    /**
     * @inheritdoc ImETH_Burner
     */
    function triggerWithdrawal() external returns (uint256 requestId) {
        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));

        requestId = IStaking(STAKING).unstakeRequest(uint128(amount), uint128(IStaking(STAKING).mETHToETH(amount)));

        _addRequestId(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc ImETH_Burner
     */
    function triggerBurn(uint256 requestId) external {
        _removeRequestId(requestId);

        IStaking(STAKING).claimUnstakeRequest(requestId);

        new SelfDestruct{value: address(this).balance}();

        emit TriggerBurn(msg.sender, requestId);
    }

    receive() external payable {}
}
