// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";

import {IDC_sfrxETH_Burner} from "src/interfaces/burners/DC_sfrxETH/IDC_sfrxETH_Burner.sol";
import {IFraxEtherRedemptionQueue} from "src/interfaces/burners/DC_sfrxETH/IFraxEtherRedemptionQueue.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract DC_sfrxETH_Burner is IDC_sfrxETH_Burner, IERC721Receiver {
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IDC_sfrxETH_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IDC_sfrxETH_Burner
     */
    address public immutable FRAX_ETHER_REDEMPTION_QUEUE;

    EnumerableSet.UintSet private _requestIds;

    constructor(address collateral, address fraxEtherRedemptionQueue) {
        COLLATERAL = collateral;

        FRAX_ETHER_REDEMPTION_QUEUE = fraxEtherRedemptionQueue;

        IERC20(COLLATERAL).approve(FRAX_ETHER_REDEMPTION_QUEUE, type(uint256).max);
    }

    /**
     * @inheritdoc IDC_sfrxETH_Burner
     */
    function requestIdsLength() external view returns (uint256) {
        return _requestIds.length();
    }

    /**
     * @inheritdoc IDC_sfrxETH_Burner
     */
    function requestIds(uint256 index, uint256 maxRequestIds) external view returns (uint256[] memory requestIds_) {
        uint256 length = Math.min(index + maxRequestIds, _requestIds.length()) - index;

        requestIds_ = new uint256[](length);
        for (uint256 i; i < length;) {
            requestIds_[i] = _requestIds.at(index);
            unchecked {
                ++i;
                ++index;
            }
        }
    }

    /**
     * @inheritdoc IDC_sfrxETH_Burner
     */
    function triggerWithdrawal() external returns (uint256 requestId) {
        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));

        requestId = IFraxEtherRedemptionQueue(FRAX_ETHER_REDEMPTION_QUEUE).enterRedemptionQueueViaSfrxEth(
            address(this), uint120(amount)
        );

        _requestIds.add(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc IDC_sfrxETH_Burner
     */
    function triggerBurn(uint256 requestId) external {
        if (!_requestIds.remove(requestId)) {
            revert InvalidRequestId();
        }

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
