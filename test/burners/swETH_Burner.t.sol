// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {swETH_Burner} from "../../src/contracts/burners/swETH_Burner.sol";

import {ISwEXIT} from "../../src/interfaces/burners/swETH/ISwEXIT.sol";
import {ISwETH} from "../../src/interfaces/burners/swETH/ISwETH.sol";
import {IswETH_Burner} from "../../src/interfaces/burners/swETH/IswETH_Burner.sol";
import {IUintRequests} from "../../src/interfaces/common/IUintRequests.sol";

import {IERC20, IWETH} from "test/mocks/AaveV3Borrow.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract swETH_BurnerTest is Test {
    IWETH private weth = IWETH(WETH);

    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    swETH_Burner burner;

    address public constant COLLATERAL = 0xf951E335afb289353dc249e82926178EaC7DEd78;
    address public constant SWEXIT = 0x48C11b86807627AF70a34662D4865cF854251663;
    address public constant REPRICING_ORACLE = 0x289d600447A74B952AD16F0BD53b8eaAac2d2D71;

    uint256 public withdrawRequestMaximum;
    uint256 public withdrawRequestMinimum;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vm.deal(address(this), 1_000_000 ether);

        ISwETH(COLLATERAL).deposit{value: 500_000 ether}();

        withdrawRequestMaximum = ISwEXIT(SWEXIT).withdrawRequestMaximum();
        withdrawRequestMinimum = ISwEXIT(SWEXIT).withdrawRequestMinimum();
    }

    function test_Create() public {
        burner = new swETH_Burner(COLLATERAL, SWEXIT);
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.SWEXIT(), SWEXIT);
        assertEq(IERC20(COLLATERAL).allowance(address(burner), SWEXIT), type(uint256).max);
    }

    struct TempStruct {
        uint256 lastRequestId_;
        uint256 initCollateralBalance;
    }

    function test_TriggerWithdrawal(uint256 depositAmount1, uint256 depositAmount2, uint256 maxRequests) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum, 10_000 ether);
        depositAmount2 = bound(depositAmount2, withdrawRequestMinimum, 10_000 ether);
        maxRequests = bound(maxRequests, 1, type(uint256).max);

        burner = new swETH_Burner(COLLATERAL, SWEXIT);
        vm.deal(address(burner), 0);

        TempStruct memory temp = TempStruct({
            lastRequestId_: ISwEXIT(SWEXIT).getLastTokenIdCreated(),
            initCollateralBalance: IERC20(COLLATERAL).balanceOf(address(this))
        });

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);
        (uint256 firstRequestId, uint256 lastRequestId) = burner.triggerWithdrawal(maxRequests);

        uint256 N1 = depositAmount1 / withdrawRequestMaximum;
        if (depositAmount1 % withdrawRequestMaximum >= withdrawRequestMinimum) {
            N1 += 1;
        }
        uint256 withdrawal1;
        if (maxRequests < N1) {
            N1 = maxRequests;

            withdrawal1 = N1 * withdrawRequestMaximum;
        } else {
            withdrawal1 = (N1 - 1) * withdrawRequestMaximum;
            if (depositAmount1 % withdrawRequestMaximum >= withdrawRequestMinimum) {
                withdrawal1 += depositAmount1 % withdrawRequestMaximum;
            } else {
                withdrawal1 += withdrawRequestMaximum;
            }
        }

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1 - withdrawal1);

        assertEq(firstRequestId, temp.lastRequestId_ + 1);
        assertEq(lastRequestId, temp.lastRequestId_ + N1);
        assertEq(burner.requestIdsLength(), N1);
        uint256[] memory requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, N1);
        for (uint256 i; i < N1; ++i) {
            assertEq(requestsIds[i], temp.lastRequestId_ + i + 1);
        }
        requestsIds = burner.requestIds(0, 0);
        assertEq(requestsIds.length, 0);
        requestsIds = burner.requestIds(0, 1);
        assertEq(requestsIds.length, 1);
        assertEq(requestsIds[0], temp.lastRequestId_ + 1);
        if (N1 > 1) {
            requestsIds = burner.requestIds(1, 1);
            assertEq(requestsIds.length, 1);
            assertEq(requestsIds[0], temp.lastRequestId_ + 2);

            requestsIds = burner.requestIds(1, 11_111);
            assertEq(requestsIds.length, N1 - 1);
            for (uint256 i; i < N1 - 1; ++i) {
                assertEq(requestsIds[i], temp.lastRequestId_ + i + 2);
            }
        }

        if (depositAmount1 + depositAmount2 <= temp.initCollateralBalance) {
            IERC20(COLLATERAL).transfer(address(burner), depositAmount2);

            assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount2 + (depositAmount1 - withdrawal1));
            (firstRequestId, lastRequestId) = burner.triggerWithdrawal(maxRequests);

            uint256 N2 = (depositAmount2 + (depositAmount1 - withdrawal1)) / withdrawRequestMaximum;
            if ((depositAmount2 + (depositAmount1 - withdrawal1)) % withdrawRequestMaximum >= withdrawRequestMinimum) {
                N2 += 1;
            }
            uint256 withdrawal2;
            if (maxRequests < N2) {
                N2 = maxRequests;

                withdrawal2 = N2 * withdrawRequestMaximum;
            } else {
                withdrawal2 = (N2 - 1) * withdrawRequestMaximum;
                if (
                    (depositAmount2 + (depositAmount1 - withdrawal1)) % withdrawRequestMaximum >= withdrawRequestMinimum
                ) {
                    withdrawal2 += (depositAmount2 + (depositAmount1 - withdrawal1)) % withdrawRequestMaximum;
                } else {
                    withdrawal2 += withdrawRequestMaximum;
                }
            }

            assertEq(
                IERC20(COLLATERAL).balanceOf(address(burner)),
                (depositAmount1 - withdrawal1) + depositAmount2 - withdrawal2
            );

            assertEq(firstRequestId, temp.lastRequestId_ + N1 + 1);
            assertEq(lastRequestId, temp.lastRequestId_ + N1 + N2);
            assertEq(burner.requestIdsLength(), N1 + N2);
            requestsIds = burner.requestIds(0, type(uint256).max);
            assertEq(requestsIds.length, N1 + N2);
            for (uint256 i; i < N1 + N2; ++i) {
                assertEq(requestsIds[i], temp.lastRequestId_ + i + 1);
            }
            requestsIds = burner.requestIds(0, 0);
            assertEq(requestsIds.length, 0);
            requestsIds = burner.requestIds(0, 1);
            assertEq(requestsIds.length, 1);
            assertEq(requestsIds[0], temp.lastRequestId_ + 1);
            if (N1 + N2 > 1) {
                requestsIds = burner.requestIds(1, 1);
                assertEq(requestsIds.length, 1);
                assertEq(requestsIds[0], temp.lastRequestId_ + 2);

                requestsIds = burner.requestIds(1, 11_111);
                assertEq(requestsIds.length, N1 + N2 - 1);
                for (uint256 i; i < N1 + N2 - 1; ++i) {
                    assertEq(requestsIds[i], temp.lastRequestId_ + i + 2);
                }
            }
        }
    }

    function test_TriggerWithdrawalRevertInsufficientWithdrawal(
        uint256 depositAmount1
    ) public {
        depositAmount1 = bound(depositAmount1, 1, withdrawRequestMinimum - 1);

        burner = new swETH_Burner(COLLATERAL, SWEXIT);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IswETH_Burner.InsufficientWithdrawal.selector);
        burner.triggerWithdrawal(0);

        vm.expectRevert(IswETH_Burner.InsufficientWithdrawal.selector);
        burner.triggerWithdrawal(1);
    }

    function test_TriggerBurn(
        uint256 depositAmount1
    ) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum, 10_000 ether);

        burner = new swETH_Burner(COLLATERAL, SWEXIT);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        (uint256 firstRequestId, uint256 lastRequestId) = burner.triggerWithdrawal(type(uint256).max);

        vm.deal(SWEXIT, 100_000 ether);
        vm.startPrank(REPRICING_ORACLE);
        ISwEXIT(SWEXIT).processWithdrawals(lastRequestId);
        vm.stopPrank();

        assertEq(address(burner).balance, 0);
        burner.triggerBurn(firstRequestId);
        assertEq(address(burner).balance, 0);

        uint256[] memory requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, lastRequestId - firstRequestId);
        for (uint256 i; i < requestsIds.length; ++i) {
            assertTrue(firstRequestId != requestsIds[i]);
        }
    }

    function test_TriggerBurnRevertInvalidRequestId(
        uint256 depositAmount1
    ) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum, 10_000 ether);

        burner = new swETH_Burner(COLLATERAL, SWEXIT);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        (, uint256 lastRequestId) = burner.triggerWithdrawal(type(uint256).max);

        vm.deal(SWEXIT, 100_000 ether);
        vm.startPrank(REPRICING_ORACLE);
        ISwEXIT(SWEXIT).processWithdrawals(lastRequestId);
        vm.stopPrank();

        vm.expectRevert(IUintRequests.InvalidRequestId.selector);
        burner.triggerBurn(0);
    }
}
