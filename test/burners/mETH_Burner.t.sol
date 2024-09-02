// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {mETH_Burner} from "../../src/contracts/burners/mETH_Burner.sol";

import {IStaking} from "../../src/interfaces/burners/mETH/IStaking.sol";
import {IMETH} from "../../src/interfaces/burners/mETH/IMETH.sol";
import {ImETH_Burner} from "../../src/interfaces/burners/mETH/ImETH_Burner.sol";
import {IUintRequests} from "../../src/interfaces/IUintRequests.sol";

import {IERC20} from "test/mocks/AaveV3Borrow.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract mETH_BurnerTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    mETH_Burner burner;

    address public constant COLLATERAL = 0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa;
    address public constant STAKING = 0xe3cBd06D7dadB3F4e6557bAb7EdD924CD1489E8f;
    address public constant UNSTAKE_REQUESTS_MANAGER = 0x38fDF7b489316e03eD8754ad339cb5c4483FDcf9;
    address public constant ORACLE = 0x8735049F496727f824Cc0f2B174d826f5c408192;
    address public constant MANTLE_SECURITY_COUNCIL = 0x4e59e778a0fb77fBb305637435C62FaeD9aED40f;
    address public constant PROXY_ADMIN_TIMELOCK = 0xc26016f1166bE7b6c5611AAB104122E0f6c2aCE2;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vm.deal(address(this), 1_000_000 ether);

        vm.startPrank(STAKING);
        IMETH(COLLATERAL).mint(address(this), 500_000 ether);
        vm.stopPrank();
    }

    function test_Create() public {
        burner = new mETH_Burner(COLLATERAL);
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.STAKING(), STAKING);
        assertEq(IERC20(COLLATERAL).allowance(address(burner), STAKING), type(uint256).max);
    }

    function test_TriggerWithdrawal(uint256 depositAmount1, uint256 depositAmount2) public {
        depositAmount1 = bound(depositAmount1, IStaking(STAKING).minimumUnstakeBound(), 10_000 ether);
        depositAmount2 = bound(depositAmount2, IStaking(STAKING).minimumUnstakeBound(), 10_000 ether);

        burner = new mETH_Burner(COLLATERAL);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);
        uint256 nextRequestId = IUnstakeRequestsManagerWrite(UNSTAKE_REQUESTS_MANAGER).nextRequestId();
        assertEq(address(burner).balance, 0);
        uint256 requestsId = burner.triggerWithdrawal();
        assertEq(address(burner).balance, 0);
        assertEq(requestsId, nextRequestId);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);

        assertEq(burner.requestIdsLength(), 1);
        uint256[] memory requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, 1);
        for (uint256 i; i < 1; ++i) {
            assertEq(requestsIds[i], nextRequestId + i);
        }
        requestsIds = burner.requestIds(0, 0);
        assertEq(requestsIds.length, 0);
        requestsIds = burner.requestIds(0, 1);
        assertEq(requestsIds.length, 1);
        assertEq(requestsIds[0], nextRequestId);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount2);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount2);
        nextRequestId = IUnstakeRequestsManagerWrite(UNSTAKE_REQUESTS_MANAGER).nextRequestId();
        assertEq(address(burner).balance, 0);
        requestsId = burner.triggerWithdrawal();
        assertEq(address(burner).balance, 0);
        assertEq(requestsId, nextRequestId);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);

        assertEq(burner.requestIdsLength(), 2);
        requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, 2);
        for (uint256 i; i < 2; ++i) {
            assertEq(requestsIds[i], nextRequestId - 1 + i);
        }
        requestsIds = burner.requestIds(0, 0);
        assertEq(requestsIds.length, 0);
        requestsIds = burner.requestIds(0, 2);
        assertEq(requestsIds.length, 2);
        assertEq(requestsIds[0], nextRequestId - 1);
        assertEq(requestsIds[1], nextRequestId);
    }

    function test_TriggerBurn(
        uint256 depositAmount1
    ) public {
        depositAmount1 = bound(depositAmount1, IStaking(STAKING).minimumUnstakeBound(), 10_000 ether);

        burner = new mETH_Burner(COLLATERAL);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 requestsId = burner.triggerWithdrawal();

        vm.deal(STAKING, 1_000_000 ether);
        vm.startPrank(STAKING);
        IUnstakeRequestsManagerWrite(UNSTAKE_REQUESTS_MANAGER).allocateETH{value: 100_000 ether}();
        vm.stopPrank();

        Oracle newOracle = new Oracle();

        vm.startPrank(PROXY_ADMIN_TIMELOCK);
        ITransparentUpgradeableProxy(ORACLE).upgradeTo(address(newOracle));
        vm.stopPrank();

        assertEq(address(burner).balance, 0);
        burner.triggerBurn(requestsId);
        assertEq(address(burner).balance, 0);

        assertEq(burner.requestIdsLength(), 0);
    }

    function test_TriggerBurnRevertInvalidRequestId(
        uint256 depositAmount1
    ) public {
        depositAmount1 = bound(depositAmount1, IStaking(STAKING).minimumUnstakeBound(), 10_000 ether);

        burner = new mETH_Burner(COLLATERAL);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        burner.triggerWithdrawal();

        vm.deal(STAKING, 1_000_000 ether);
        vm.startPrank(STAKING);
        IUnstakeRequestsManagerWrite(UNSTAKE_REQUESTS_MANAGER).allocateETH{value: 100_000 ether}();
        vm.stopPrank();

        Oracle newOracle = new Oracle();

        vm.startPrank(PROXY_ADMIN_TIMELOCK);
        ITransparentUpgradeableProxy(ORACLE).upgradeTo(address(newOracle));
        vm.stopPrank();

        vm.expectRevert(IUintRequests.InvalidRequestId.selector);
        burner.triggerBurn(0);
    }
}

interface ITransparentUpgradeableProxy {
    function admin() external view returns (address);

    function implementation() external view returns (address);

    function changeAdmin(
        address
    ) external;

    function upgradeTo(
        address
    ) external;

    function upgradeToAndCall(address, bytes memory) external payable;
}

interface IUnstakeRequestsManagerWrite {
    /// @notice Returns the ID of the next unstake requests to be created.
    function nextRequestId() external view returns (uint256);

    /// @notice Allocate ether into the contract.
    /// @dev Handles incoming ether from the staking contract, increasing the allocatedETHForClaims counter by the value
    /// of the incoming allocatedETH.
    function allocateETH() external payable;
}

interface IOracle {
    /// @notice The records stored by the oracle contract informing the protocol about consensus layer activity. It is
    /// computed and reported by off-chain oracle services.
    /// @dev "current" quantities refer to the state at the `updateEndBlock` block number.
    /// @dev "cumulative" quantities refer to sums up to the `updateEndBlock` block number.
    /// @dev "window" quantities refer to sums over the block window between the `updateStartBlock` and `updateEndBlock`.
    /// @param updateStartBlock The start of the oracle record block window. This should be 1 higher than the
    /// updateEndBlock of the previous oracle record.
    /// @param updateEndBlock The block number up to which this oracle record was computed (inclusive).
    /// @param currentNumValidatorsNotWithdrawable The number of our validators that do not have the withdrawable status.
    /// @param cumulativeNumValidatorsWithdrawable The total number of our validators that have the withdrawable status.
    /// These validators have either the status `withdrawal_possible` or `withdrawal_done`. Note: validators can
    /// fluctuate between the two statuses due to top ups.
    /// @param windowWithdrawnPrincipalAmount The amount of principal that has been withdrawn from the consensus layer in
    /// the analyzed block window.
    /// @param windowWithdrawnRewardAmount The amount of rewards that has been withdrawn from the consensus layer in the
    /// analysed block window.
    /// @param currentTotalValidatorBalance The total amount of ETH in the consensus layer (i.e. the sum of all validator
    /// balances). This is one of the major quantities to compute the total value controlled by the protocol.
    /// @param cumulativeProcessedDepositAmount The total amount of ETH that has been deposited into and processed by the
    /// consensus layer. This is used to prevent double counting of the ETH deposited to the consensus layer.
    struct OracleRecord {
        uint64 updateStartBlock;
        uint64 updateEndBlock;
        uint64 currentNumValidatorsNotWithdrawable;
        uint64 cumulativeNumValidatorsWithdrawable;
        uint128 windowWithdrawnPrincipalAmount;
        uint128 windowWithdrawnRewardAmount;
        uint128 currentTotalValidatorBalance;
        uint128 cumulativeProcessedDepositAmount;
    }

    /// @notice Returns the latest validated record.
    /// @return `OracleRecord` The latest validated record.
    function latestRecord() external view returns (OracleRecord memory);
}

contract Oracle is IOracle {
    function latestRecord() external view override returns (OracleRecord memory) {
        return OracleRecord({
            updateStartBlock: 0,
            updateEndBlock: uint64(block.timestamp * 2),
            currentNumValidatorsNotWithdrawable: 0,
            cumulativeNumValidatorsWithdrawable: 0,
            windowWithdrawnPrincipalAmount: 0,
            windowWithdrawnRewardAmount: 0,
            currentTotalValidatorBalance: 0,
            cumulativeProcessedDepositAmount: 0
        });
    }
}
