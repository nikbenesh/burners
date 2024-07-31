// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";
import {UintRequests} from "src/contracts/UintRequests.sol";

import {IDC_wstETH_Burner} from "src/interfaces/burners/DC_wstETH/IDC_wstETH_Burner.sol";
import {IWithdrawalQueue} from "src/interfaces/burners/DC_wstETH/IWithdrawalQueue.sol";
import {IWstETH} from "src/interfaces/burners/DC_wstETH/IWstETH.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract DC_wstETH_Burner is UintRequests, IDC_wstETH_Burner {
    using Math for uint256;

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    address public immutable STETH;

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    address public immutable LIDO_WITHDRAWAL_QUEUE;

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    uint256 public immutable MIN_STETH_WITHDRAWAL_AMOUNT;

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    uint256 public immutable MAX_STETH_WITHDRAWAL_AMOUNT;

    constructor(address collateral, address lidoWithdrawalQueue) {
        COLLATERAL = collateral;

        LIDO_WITHDRAWAL_QUEUE = lidoWithdrawalQueue;

        STETH = IWithdrawalQueue(lidoWithdrawalQueue).STETH();
        MIN_STETH_WITHDRAWAL_AMOUNT = IWithdrawalQueue(lidoWithdrawalQueue).MIN_STETH_WITHDRAWAL_AMOUNT();
        MAX_STETH_WITHDRAWAL_AMOUNT = IWithdrawalQueue(lidoWithdrawalQueue).MAX_STETH_WITHDRAWAL_AMOUNT();

        IERC20(STETH).approve(LIDO_WITHDRAWAL_QUEUE, type(uint256).max);
    }

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    function triggerWithdrawal(uint256 maxRequests) external returns (uint256[] memory requestIds_) {
        IWstETH(COLLATERAL).unwrap(IERC20(COLLATERAL).balanceOf(address(this)));
        uint256 stETHAmount = IERC20(STETH).balanceOf(address(this));

        uint256 requests = stETHAmount / MAX_STETH_WITHDRAWAL_AMOUNT;
        if (stETHAmount % MAX_STETH_WITHDRAWAL_AMOUNT >= MIN_STETH_WITHDRAWAL_AMOUNT) {
            requests += 1;
        }
        requests = Math.min(requests, maxRequests);

        if (requests == 0) {
            revert InsufficientWithdrawal();
        }

        uint256[] memory amounts = new uint256[](requests);
        uint256 requestsMinusOne = requests - 1;
        for (uint256 i; i < requestsMinusOne; ++i) {
            amounts[i] = MAX_STETH_WITHDRAWAL_AMOUNT;
        }
        amounts[requestsMinusOne] =
            Math.min(stETHAmount - requestsMinusOne * MAX_STETH_WITHDRAWAL_AMOUNT, MAX_STETH_WITHDRAWAL_AMOUNT);

        requestIds_ = IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).requestWithdrawals(amounts, address(this));

        for (uint256 i; i < requests; ++i) {
            _addRequestId(requestIds_[i]);
        }

        emit TriggerWithdrawal(msg.sender, requestIds_);
    }

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    function triggerBurn(uint256 requestId) external {
        _removeRequestId(requestId);

        IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).claimWithdrawal(requestId);

        new SelfDestruct{value: address(this).balance}();

        emit TriggerBurn(msg.sender, requestId);
    }

    /**
     * @inheritdoc IDC_wstETH_Burner
     */
    function triggerBurnBatch(uint256[] calldata requestIds_, uint256[] calldata hints) external {
        uint256 length = requestIds_.length;
        for (uint256 i; i < length; ++i) {
            _removeRequestId(requestIds_[i]);
        }

        IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).claimWithdrawals(requestIds_, hints);

        new SelfDestruct{value: address(this).balance}();

        emit TriggerBurnBatch(msg.sender, requestIds_);
    }

    receive() external payable {}
}
