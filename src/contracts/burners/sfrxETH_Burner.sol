// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "../SelfDestruct.sol";
import {UintRequests} from "../UintRequests.sol";

import {IFraxEtherRedemptionQueue} from "../../interfaces/burners/sfrxETH/IFraxEtherRedemptionQueue.sol";
import {IsfrxETH_Burner} from "../../interfaces/burners/sfrxETH/IsfrxETH_Burner.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract sfrxETH_Burner is UintRequests, IsfrxETH_Burner, IERC721Receiver {
    /**
     * @inheritdoc IsfrxETH_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IsfrxETH_Burner
     */
    address public immutable FRAX_ETHER_REDEMPTION_QUEUE;

    constructor(address collateral, address fraxEtherRedemptionQueue) {
        COLLATERAL = collateral;

        FRAX_ETHER_REDEMPTION_QUEUE = fraxEtherRedemptionQueue;

        IERC20(COLLATERAL).approve(FRAX_ETHER_REDEMPTION_QUEUE, type(uint256).max);
    }

    /**
     * @inheritdoc IsfrxETH_Burner
     */
    function triggerWithdrawal() external returns (uint256 requestId) {
        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));

        requestId = IFraxEtherRedemptionQueue(FRAX_ETHER_REDEMPTION_QUEUE).enterRedemptionQueueViaSfrxEth(
            address(this), uint120(amount)
        );

        _addRequestId(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc IsfrxETH_Burner
     */
    function triggerBurn(
        uint256 requestId
    ) external {
        _removeRequestId(requestId);

        IFraxEtherRedemptionQueue(FRAX_ETHER_REDEMPTION_QUEUE).burnRedemptionTicketNft(
            requestId, payable(address(this))
        );

        new SelfDestruct{value: address(this).balance}();

        emit TriggerBurn(msg.sender, requestId);
    }

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
