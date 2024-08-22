// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {ETHx_Burner} from "src/contracts/burners/ETHx/ETHx_Burner.sol";
import {ETHx_Miniburner} from "src/contracts/burners/ETHx/ETHx_Miniburner.sol";

import {IETHx_Burner} from "src/interfaces/burners/ETHx/IETHx_Burner.sol";
import {IStaderConfig} from "src/interfaces/burners/ETHx/IStaderConfig.sol";
import {IStaderStakePoolsManager} from "src/interfaces/burners/ETHx/IStaderStakePoolsManager.sol";
import {IUserWithdrawalManager} from "src/interfaces/burners/ETHx/IUserWithdrawalManager.sol";
import {IAddressRequests} from "src/interfaces/IAddressRequests.sol";

import {IERC20, IWETH} from "test/mocks/AaveV3Borrow.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract ETHx_BurnerTest is Test {
    IWETH private weth = IWETH(WETH);

    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    ETHx_Burner burner;

    address public constant COLLATERAL = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;
    address public constant STADER_CONFIG = 0x4ABEF2263d5A5ED582FC9A9789a41D85b68d69DB;
    address public constant STAKE_POOLS_MANAGER = 0xcf5EA1b38380f6aF39068375516Daf40Ed70D299;
    address public constant USER_WITHDRAW_MANAGER = 0x9F0491B32DBce587c50c4C43AB303b06478193A7;

    // in shares
    uint256 public withdrawRequestMaximum;
    uint256 public withdrawRequestMinimum;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vm.deal(address(this), 1_000_000 ether);

        vm.startPrank(STAKE_POOLS_MANAGER);
        IETHx(COLLATERAL).mint(address(this), 500_000 ether);
        vm.stopPrank();

        withdrawRequestMinimum = IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewDeposit(
            IStaderConfig(STADER_CONFIG).getMinWithdrawAmount()
        ) + 1;
        while (
            IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(withdrawRequestMinimum - 1)
                >= IStaderConfig(STADER_CONFIG).getMinWithdrawAmount()
        ) {
            withdrawRequestMinimum -= 1;
        }

        withdrawRequestMaximum = IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewDeposit(
            IStaderConfig(STADER_CONFIG).getMaxWithdrawAmount()
        );
        while (
            IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(withdrawRequestMaximum + 1)
                <= IStaderConfig(STADER_CONFIG).getMaxWithdrawAmount()
        ) {
            withdrawRequestMaximum += 1;
        }
    }

    function test_Create() public {
        address miniburner = address(new ETHx_Miniburner(COLLATERAL, STADER_CONFIG));
        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG, miniburner);
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.STADER_CONFIG(), STADER_CONFIG);
        assertEq(burner.USER_WITHDRAW_MANAGER(), USER_WITHDRAW_MANAGER);
        assertEq(burner.STAKE_POOLS_MANAGER(), STAKE_POOLS_MANAGER);
        assertEq(IERC20(COLLATERAL).allowance(address(burner), USER_WITHDRAW_MANAGER), type(uint256).max);
    }

    struct TempStruct {
        uint256 firstRequestId_;
        uint256 initCollateralBalance;
    }

    function test_TriggerWithdrawal(uint256 depositAmount1, uint256 depositAmount2, uint256 maxRequests) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum / 2, 50_000 ether);
        depositAmount2 = bound(depositAmount2, withdrawRequestMinimum / 2, 50_000 ether);
        maxRequests = bound(maxRequests, 1, type(uint256).max);

        address miniburner = address(new ETHx_Miniburner(COLLATERAL, STADER_CONFIG));
        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG, miniburner);
        vm.deal(address(burner), 0);

        TempStruct memory temp = TempStruct({
            firstRequestId_: IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestId(),
            initCollateralBalance: IERC20(COLLATERAL).balanceOf(address(this))
        });

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.assume(
            IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(depositAmount1)
                >= IStaderConfig(STADER_CONFIG).getMinWithdrawAmount()
        );

        address[] memory requestIds =
            burner.triggerWithdrawal(withdrawRequestMinimum, withdrawRequestMaximum, maxRequests);

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

        assertEq(burner.requestIdInternal(requestIds[0]), temp.firstRequestId_);
        assertEq(burner.requestIdInternal(requestIds[requestIds.length - 1]), temp.firstRequestId_ + N1 - 1);
        assertEq(burner.requestIdsLength(), N1);
        address[] memory requestIds_ = burner.requestIds(0, type(uint256).max);
        assertEq(requestIds_.length, N1);
        for (uint256 i; i < N1; ++i) {
            assertEq(burner.requestIdInternal(requestIds_[i]), temp.firstRequestId_ + i);
        }
        requestIds_ = burner.requestIds(0, 0);
        assertEq(requestIds_.length, 0);
        requestIds_ = burner.requestIds(0, 1);
        assertEq(requestIds_.length, 1);
        assertEq(burner.requestIdInternal(requestIds_[0]), temp.firstRequestId_);
        if (N1 > 1) {
            requestIds_ = burner.requestIds(1, 1);
            assertEq(requestIds_.length, 1);
            assertEq(burner.requestIdInternal(requestIds_[0]), temp.firstRequestId_ + 1);

            requestIds_ = burner.requestIds(1, 11_111);
            assertEq(requestIds_.length, N1 - 1);
            for (uint256 i; i < N1 - 1; ++i) {
                assertEq(burner.requestIdInternal(requestIds_[i]), temp.firstRequestId_ + i + 1);
            }
        }

        if (depositAmount1 + depositAmount2 <= temp.initCollateralBalance) {
            IERC20(COLLATERAL).transfer(address(burner), depositAmount2);
            vm.assume(
                IStaderStakePoolsManager(STAKE_POOLS_MANAGER).previewWithdraw(
                    depositAmount2 + (depositAmount1 - withdrawal1)
                ) >= IStaderConfig(STADER_CONFIG).getMinWithdrawAmount()
            );

            requestIds = burner.triggerWithdrawal(withdrawRequestMinimum, withdrawRequestMaximum, maxRequests);

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

            assertEq(burner.requestIdInternal(requestIds[0]), temp.firstRequestId_ + N1);
            assertEq(burner.requestIdInternal(requestIds[requestIds.length - 1]), temp.firstRequestId_ + N1 + N2 - 1);

            assertEq(burner.requestIdsLength(), N1 + N2);
            requestIds_ = burner.requestIds(0, type(uint256).max);
            assertEq(requestIds_.length, N1 + N2);
            for (uint256 i; i < N1 + N2; ++i) {
                assertEq(burner.requestIdInternal(requestIds_[i]), temp.firstRequestId_ + i);
            }
            requestIds_ = burner.requestIds(0, 0);
            assertEq(requestIds_.length, 0);
            requestIds_ = burner.requestIds(0, 1);
            assertEq(requestIds_.length, 1);
            assertEq(burner.requestIdInternal(requestIds_[0]), temp.firstRequestId_);
            if (N1 + N2 > 1) {
                requestIds_ = burner.requestIds(1, 1);
                assertEq(requestIds_.length, 1);
                assertEq(burner.requestIdInternal(requestIds_[0]), temp.firstRequestId_ + 1);

                requestIds_ = burner.requestIds(1, 11_111);
                assertEq(requestIds_.length, N1 + N2 - 1);
                for (uint256 i; i < N1 + N2 - 1; ++i) {
                    assertEq(burner.requestIdInternal(requestIds_[i]), temp.firstRequestId_ + i + 1);
                }
            }
        }
    }

    function test_TriggerWithdrawalRevertInvalidHints(
        uint256 depositAmount1,
        uint256 depositAmount2,
        uint256 maxRequests,
        uint256 withdrawRequestMinimum_,
        uint256 withdrawRequestMaximum_
    ) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum / 2, 50_000 ether);
        depositAmount2 = bound(depositAmount2, withdrawRequestMinimum / 2, 50_000 ether);
        maxRequests = bound(maxRequests, 1, type(uint256).max);
        withdrawRequestMinimum_ = bound(withdrawRequestMinimum_, 0, type(uint128).max);
        withdrawRequestMaximum_ = bound(withdrawRequestMaximum_, 0, type(uint128).max);

        address miniburner = address(new ETHx_Miniburner(COLLATERAL, STADER_CONFIG));
        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG, miniburner);
        vm.deal(address(burner), 0);

        vm.assume(withdrawRequestMinimum_ != withdrawRequestMinimum);
        vm.assume(withdrawRequestMaximum_ != withdrawRequestMaximum);

        vm.expectRevert(IETHx_Burner.InvalidHints.selector);
        burner.triggerWithdrawal(withdrawRequestMinimum_, withdrawRequestMaximum_, maxRequests);
    }

    function test_TriggerWithdrawalRevertInsufficientWithdrawal(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 1, withdrawRequestMinimum - 1);

        address miniburner = address(new ETHx_Miniburner(COLLATERAL, STADER_CONFIG));
        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG, miniburner);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IETHx_Burner.InsufficientWithdrawal.selector);
        burner.triggerWithdrawal(withdrawRequestMinimum, withdrawRequestMaximum, 0);

        vm.expectRevert(IETHx_Burner.InsufficientWithdrawal.selector);
        burner.triggerWithdrawal(withdrawRequestMinimum, withdrawRequestMaximum, 1);
    }

    function test_TriggerBurn(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum, 50_000 ether);

        address miniburner = address(new ETHx_Miniburner(COLLATERAL, STADER_CONFIG));
        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG, miniburner);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        address[] memory requestIds =
            burner.triggerWithdrawal(withdrawRequestMinimum, withdrawRequestMaximum, type(uint256).max);

        vm.roll(block.number + IStaderConfig(STADER_CONFIG).getMinBlockDelayToFinalizeWithdrawRequest());
        vm.deal(STAKE_POOLS_MANAGER, 500_000 ether);
        while (
            IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestIdToFinalize()
                <= burner.requestIdInternal(requestIds[requestIds.length - 1])
        ) {
            IUserWithdrawalManager(USER_WITHDRAW_MANAGER).finalizeUserWithdrawalRequest();
        }

        assertEq(address(burner).balance, 0);
        burner.triggerBurn(requestIds[0]);
        assertEq(address(burner).balance, 0);

        address[] memory requestIds_ = burner.requestIds(0, type(uint256).max);
        assertEq(requestIds_.length, requestIds.length - 1);
        for (uint256 i; i < requestIds_.length; ++i) {
            assertTrue(requestIds[0] != requestIds_[i]);
        }
    }

    function test_TriggerBurnRevertInvalidRequestId(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum, 50_000 ether);

        address miniburner = address(new ETHx_Miniburner(COLLATERAL, STADER_CONFIG));
        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG, miniburner);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        address[] memory requestIds =
            burner.triggerWithdrawal(withdrawRequestMinimum, withdrawRequestMaximum, type(uint256).max);

        vm.roll(block.number + IStaderConfig(STADER_CONFIG).getMinBlockDelayToFinalizeWithdrawRequest());
        vm.deal(STAKE_POOLS_MANAGER, 500_000 ether);
        while (
            IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestIdToFinalize()
                <= burner.requestIdInternal(requestIds[requestIds.length - 1])
        ) {
            IUserWithdrawalManager(USER_WITHDRAW_MANAGER).finalizeUserWithdrawalRequest();
        }

        vm.expectRevert(IAddressRequests.InvalidRequestId.selector);
        burner.triggerBurn(address(0));
    }
}

interface IETHx {
    /**
     * @notice Mints ethX when called by an authorized caller
     * @param to the account to mint to
     * @param amount the amount of ethX to mint
     */
    function mint(address to, uint256 amount) external;
}
