// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";

import {IDC_mETH_Burner} from "src/interfaces/burners/DC_mETH/IDC_mETH_Burner.sol";
import {IStaking} from "src/interfaces/burners/DC_mETH/IStaking.sol";
import {IMETH} from "src/interfaces/burners/DC_mETH/IMETH.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DC_mETH_Burner is IDC_mETH_Burner {
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IDC_mETH_Burner
     */
    address public immutable COLLATERAL;

    /**
     * @inheritdoc IDC_mETH_Burner
     */
    address public immutable ASSET;

    /**
     * @inheritdoc IDC_mETH_Burner
     */
    address public immutable STAKING;

    EnumerableSet.UintSet private _requestIds;

    constructor(address collateral) {
        COLLATERAL = collateral;

        ASSET = IDefaultCollateral(collateral).asset();

        STAKING = IMETH(ASSET).stakingContract();

        IERC20(ASSET).approve(STAKING, type(uint256).max);
    }

    /**
     * @inheritdoc IDC_mETH_Burner
     */
    function requestIdsLength() external view returns (uint256) {
        return _requestIds.length();
    }

    /**
     * @inheritdoc IDC_mETH_Burner
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
     * @inheritdoc IDC_mETH_Burner
     */
    function triggerWithdrawal() external returns (uint256 requestId) {
        uint256 amount = IERC20(COLLATERAL).balanceOf(address(this));
        IDefaultCollateral(COLLATERAL).withdraw(address(this), amount);

        requestId = IStaking(STAKING).unstakeRequest(uint128(amount), uint128(IStaking(STAKING).mETHToETH(amount)));

        _requestIds.add(requestId);

        emit TriggerWithdrawal(msg.sender, requestId);
    }

    /**
     * @inheritdoc IDC_mETH_Burner
     */
    function triggerBurn(uint256 requestId) external {
        if (!_requestIds.remove(requestId)) {
            revert InvalidRequestId();
        }

        IStaking(STAKING).claimUnstakeRequest(requestId);

        new SelfDestruct{value: address(this).balance}();

        emit TriggerBurn(msg.sender, requestId);
    }

    receive() external payable {}
}
