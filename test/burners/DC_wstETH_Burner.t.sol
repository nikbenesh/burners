// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {DC_wstETH_Burner} from "src/contracts/burners/DC_wstETH_Burner.sol";

import {IWithdrawalQueue} from "src/interfaces/burners/DC_wstETH/IWithdrawalQueue.sol";
import {IWstETH} from "src/interfaces/burners/DC_wstETH/IWstETH.sol";
import {IDC_wstETH_Burner} from "src/interfaces/burners/DC_wstETH/IDC_wstETH_Burner.sol";

import {UniswapV3Swap, IERC20, IWETH} from "test/mocks/UniswapV3Swap.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract DC_wstETH_BurnerTest is Test {
    IWETH private weth = IWETH(WETH);

    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    UniswapV3Swap private uni;

    DC_wstETH_Burner burner;

    address public constant COLLATERAL = 0xC329400492c6ff2438472D4651Ad17389fCb843a;
    address public constant LIDO_WITHDRAWAL_QUEUE = 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    function setUp() public {
        // uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        // vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        uni = new UniswapV3Swap();
        weth.approve(address(uni), type(uint256).max);

        IERC20(WSTETH).approve(COLLATERAL, type(uint256).max);

        vm.deal(address(this), 100_000_000_000 ether);
        weth.deposit{value: 100_000_000_000 ether}();
        uint256 amountOut = uni.swapExactInputSingleHop(WETH, WSTETH, 100, 100_000_000_000 ether);

        vm.startPrank(IDefaultCollateral(COLLATERAL).limitIncreaser());
        IDefaultCollateral(COLLATERAL).increaseLimit(100_000_000_000 ether);
        vm.stopPrank();

        IDefaultCollateral(COLLATERAL).deposit(address(this), amountOut);
    }

    function test_Create() public {
        burner = new DC_wstETH_Burner(COLLATERAL, LIDO_WITHDRAWAL_QUEUE);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.ASSET(), WSTETH);
        assertEq(burner.LIDO_WITHDRAWAL_QUEUE(), LIDO_WITHDRAWAL_QUEUE);
        assertEq(burner.STETH(), STETH);
        assertEq(burner.MIN_STETH_WITHDRAWAL_AMOUNT(), 100);
        assertEq(burner.MAX_STETH_WITHDRAWAL_AMOUNT(), 1000 ether);
        assertEq(IERC20(STETH).allowance(address(burner), LIDO_WITHDRAWAL_QUEUE), type(uint256).max);
    }

    function test_TriggerWithdrawal(uint256 depositAmount1, uint256 depositAmount2, uint256 maxRequests) public {
        depositAmount1 = bound(depositAmount1, 50, 2500 ether);
        depositAmount2 = bound(depositAmount2, 50, 2500 ether);
        maxRequests = bound(maxRequests, 1, type(uint256).max);

        burner = new DC_wstETH_Burner(COLLATERAL, LIDO_WITHDRAWAL_QUEUE);

        uint256 initCollateralBalance = IERC20(COLLATERAL).balanceOf(address(this));

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 lastRequestId = IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).getLastRequestId();
        uint256 stETHAmount1 = IWstETH(WSTETH).getStETHByWstETH(depositAmount1);
        vm.assume(stETHAmount1 >= 101);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);
        uint256[] memory requestsIds = burner.triggerWithdrawal(maxRequests);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);

        uint256 N1 = stETHAmount1 / 1000 ether;
        if (stETHAmount1 % 1000 ether >= 100) {
            N1 += 1;
        }
        uint256 withdrawal1;
        if (maxRequests < N1) {
            N1 = maxRequests;

            withdrawal1 = N1 * 1000 ether;
        } else {
            withdrawal1 = (N1 - 1) * 1000 ether;
            if (stETHAmount1 % 1000 ether >= 100) {
                withdrawal1 += stETHAmount1 % 1000 ether;
            } else {
                withdrawal1 += 1000 ether;
            }
        }

        assertApproxEqAbs(IERC20(STETH).balanceOf(address(burner)), stETHAmount1 - withdrawal1, 2);

        assertEq(requestsIds.length, N1);
        for (uint256 i; i < N1; ++i) {
            assertEq(requestsIds[i], lastRequestId + i + 1);
        }
        assertEq(burner.requestIdsLength(), N1);
        requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, N1);
        for (uint256 i; i < N1; ++i) {
            assertEq(requestsIds[i], lastRequestId + i + 1);
        }
        requestsIds = burner.requestIds(0, 0);
        assertEq(requestsIds.length, 0);
        requestsIds = burner.requestIds(0, 1);
        assertEq(requestsIds.length, 1);
        assertEq(requestsIds[0], lastRequestId + 1);
        if (N1 > 1) {
            requestsIds = burner.requestIds(1, 1);
            assertEq(requestsIds.length, 1);
            assertEq(requestsIds[0], lastRequestId + 2);

            requestsIds = burner.requestIds(1, 10_000);
            assertEq(requestsIds.length, N1 - 1);
            for (uint256 i; i < N1 - 1; ++i) {
                assertEq(requestsIds[i], lastRequestId + i + 2);
            }
        }

        if (depositAmount1 + depositAmount2 <= initCollateralBalance) {
            IERC20(COLLATERAL).transfer(address(burner), depositAmount2);

            uint256 stETHAmount2 = IWstETH(WSTETH).getStETHByWstETH(depositAmount2);
            vm.assume(stETHAmount2 >= 100);
            assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount2);
            requestsIds = burner.triggerWithdrawal(maxRequests);
            assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);

            uint256 N2 = (stETHAmount2 + (stETHAmount1 - withdrawal1)) / 1000 ether;
            if ((stETHAmount2 + (stETHAmount1 - withdrawal1)) % 1000 ether >= 100) {
                N2 += 1;
            }
            uint256 withdrawal2;
            if (maxRequests < N2) {
                N2 = maxRequests;

                withdrawal2 = N2 * 1000 ether;
            } else {
                withdrawal2 = (N2 - 1) * 1000 ether;
                if ((stETHAmount2 + (stETHAmount1 - withdrawal1)) % 1000 ether >= 100) {
                    withdrawal2 += (stETHAmount2 + (stETHAmount1 - withdrawal1)) % 1000 ether;
                } else {
                    withdrawal2 += 1000 ether;
                }
            }

            assertApproxEqAbs(
                IERC20(STETH).balanceOf(address(burner)), (stETHAmount1 - withdrawal1) + stETHAmount2 - withdrawal2, 2
            );

            assertEq(requestsIds.length, N2);
            for (uint256 i; i < N2; ++i) {
                assertEq(requestsIds[i], lastRequestId + N1 + i + 1);
            }
            assertEq(burner.requestIdsLength(), N1 + N2);
            requestsIds = burner.requestIds(0, type(uint256).max);
            assertEq(requestsIds.length, N1 + N2);
            for (uint256 i; i < N1 + N2; ++i) {
                assertEq(requestsIds[i], lastRequestId + i + 1);
            }
            requestsIds = burner.requestIds(0, 0);
            assertEq(requestsIds.length, 0);
            requestsIds = burner.requestIds(0, 1);
            assertEq(requestsIds.length, 1);
            assertEq(requestsIds[0], lastRequestId + 1);
            if (N1 + N2 > 1) {
                requestsIds = burner.requestIds(1, 1);
                assertEq(requestsIds.length, 1);
                assertEq(requestsIds[0], lastRequestId + 2);

                requestsIds = burner.requestIds(1, 10_000);
                assertEq(requestsIds.length, N1 + N2 - 1);
                for (uint256 i; i < N1 + N2 - 1; ++i) {
                    assertEq(requestsIds[i], lastRequestId + i + 2);
                }
            }
        }
    }

    function test_TriggerWithdrawalRevertInsufficientWithdrawal(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 1, 100);
        uint256 stETHAmount1 = IWstETH(WSTETH).getStETHByWstETH(depositAmount1);
        vm.assume(stETHAmount1 < 100);

        burner = new DC_wstETH_Burner(COLLATERAL, LIDO_WITHDRAWAL_QUEUE);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IDC_wstETH_Burner.InsufficientWithdrawal.selector);
        burner.triggerWithdrawal(0);

        vm.expectRevert(IDC_wstETH_Burner.InsufficientWithdrawal.selector);
        burner.triggerWithdrawal(1);
    }

    function test_TriggerBurn(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 50, 2500 ether);

        burner = new DC_wstETH_Burner(COLLATERAL, LIDO_WITHDRAWAL_QUEUE);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 stETHAmount1 = IWstETH(WSTETH).getStETHByWstETH(depositAmount1);
        vm.assume(stETHAmount1 >= 101);
        uint256[] memory requestsIds = burner.triggerWithdrawal(type(uint256).max);

        vm.deal(LIDO_WITHDRAWAL_QUEUE, 100_000 ether);
        vm.startPrank(STETH);
        IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).finalize(requestsIds[0], 1e18);
        vm.stopPrank();

        assertEq(address(burner).balance, 0);
        burner.triggerBurn(requestsIds[0]);
        assertEq(address(burner).balance, 0);

        uint256[] memory requestsIds1 = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds1.length, requestsIds.length - 1);
        for (uint256 i; i < requestsIds1.length; ++i) {
            assertTrue(requestsIds[0] != requestsIds1[i]);
        }
    }

    function test_TriggerBurnRevertInvalidRequestId(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 50, 2500 ether);

        burner = new DC_wstETH_Burner(COLLATERAL, LIDO_WITHDRAWAL_QUEUE);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 stETHAmount1 = IWstETH(WSTETH).getStETHByWstETH(depositAmount1);
        vm.assume(stETHAmount1 >= 101);
        uint256[] memory requestsIds = burner.triggerWithdrawal(type(uint256).max);

        vm.deal(LIDO_WITHDRAWAL_QUEUE, 100_000 ether);
        vm.startPrank(STETH);
        IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).finalize(requestsIds[0], 1e18);
        vm.stopPrank();

        vm.expectRevert(IDC_wstETH_Burner.InvalidRequestId.selector);
        burner.triggerBurn(0);
    }

    function test_TriggerBurnBatch(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 50, 2500 ether);

        burner = new DC_wstETH_Burner(COLLATERAL, LIDO_WITHDRAWAL_QUEUE);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 stETHAmount1 = IWstETH(WSTETH).getStETHByWstETH(depositAmount1);
        vm.assume(stETHAmount1 >= 101);
        uint256[] memory requestsIds = burner.triggerWithdrawal(type(uint256).max);

        vm.deal(LIDO_WITHDRAWAL_QUEUE, 100_000 ether);
        vm.startPrank(STETH);
        for (uint256 i; i < requestsIds.length; ++i) {
            IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).finalize(requestsIds[i], 1e18);
        }
        vm.stopPrank();

        assertEq(address(burner).balance, 0);
        burner.triggerBurnBatch(
            requestsIds,
            IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).findCheckpointHints(
                requestsIds, 1, IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).getLastCheckpointIndex()
            )
        );
        assertEq(address(burner).balance, 0);

        uint256[] memory requestsIds1 = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds1.length, 0);
    }

    function test_TriggerBurnBatchRevertInvalidRequestId(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 50, 2500 ether);

        burner = new DC_wstETH_Burner(COLLATERAL, LIDO_WITHDRAWAL_QUEUE);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 stETHAmount1 = IWstETH(WSTETH).getStETHByWstETH(depositAmount1);
        vm.assume(stETHAmount1 >= 101);
        uint256[] memory requestsIds = burner.triggerWithdrawal(type(uint256).max);

        vm.deal(LIDO_WITHDRAWAL_QUEUE, 100_000 ether);
        vm.startPrank(STETH);
        for (uint256 i; i < requestsIds.length; ++i) {
            IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).finalize(requestsIds[i], 1e18);
        }
        vm.stopPrank();

        uint256[] memory hints = IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).findCheckpointHints(
            requestsIds, 1, IWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).getLastCheckpointIndex()
        );
        requestsIds[requestsIds.length - 1] = 0;
        vm.expectRevert(IDC_wstETH_Burner.InvalidRequestId.selector);
        burner.triggerBurnBatch(requestsIds, hints);
    }
}
