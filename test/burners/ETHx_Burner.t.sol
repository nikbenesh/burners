// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {ETHx_Burner} from "src/contracts/burners/ETHx_Burner.sol";

import {IETHx_Burner} from "src/interfaces/burners/ETHx/IETHx_Burner.sol";
import {IStaderConfig} from "src/interfaces/burners/ETHx/IStaderConfig.sol";
import {IStaderStakePoolsManager} from "src/interfaces/burners/ETHx/IStaderStakePoolsManager.sol";
import {IUserWithdrawalManager} from "src/interfaces/burners/ETHx/IUserWithdrawalManager.sol";

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
        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG);
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.STADER_CONFIG(), STADER_CONFIG);
        assertEq(burner.USER_WITHDRAW_MANAGER(), USER_WITHDRAW_MANAGER);
        assertEq(burner.STAKE_POOLS_MANAGER(), STAKE_POOLS_MANAGER);
        assertEq(IERC20(COLLATERAL).allowance(address(burner), USER_WITHDRAW_MANAGER), type(uint256).max);
    }

    struct TempStruct {
        uint256 firstRequestId_;
    }

    function test_TriggerWithdrawal(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum / 2, 50_000 ether);

        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG);
        vm.deal(address(burner), 0);

        TempStruct memory temp =
            TempStruct({firstRequestId_: IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestId()});

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);

        uint256 N;
        uint256 amount = IERC20(COLLATERAL).balanceOf(address(burner));
        while (true) {
            if (amount < withdrawRequestMinimum) {
                vm.expectRevert();
                burner.triggerWithdrawal(withdrawRequestMaximum);

                break;
            } else {
                uint256 balanceBefore = IERC20(COLLATERAL).balanceOf(address(burner));
                assertEq(
                    IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestId(),
                    burner.triggerWithdrawal(withdrawRequestMaximum)
                );
                assertEq(
                    balanceBefore - IERC20(COLLATERAL).balanceOf(address(burner)),
                    Math.min(amount, withdrawRequestMaximum)
                );
                amount = IERC20(COLLATERAL).balanceOf(address(burner));
                ++N;
            }
        }

        assertEq(burner.requestIdsLength(), N);
        uint256[] memory requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, N);
        for (uint256 i; i < N; ++i) {
            assertEq(requestsIds[i], temp.firstRequestId_ + i);
        }
        requestsIds = burner.requestIds(0, 0);
        assertEq(requestsIds.length, 0);
        requestsIds = burner.requestIds(0, 1);
        assertEq(requestsIds.length, Math.min(N, 1));
        if (N > 0) {
            assertEq(requestsIds[0], temp.firstRequestId_);
        }
        if (N > 1) {
            requestsIds = burner.requestIds(1, 1);
            assertEq(requestsIds.length, 1);
            assertEq(requestsIds[0], temp.firstRequestId_ + 1);

            requestsIds = burner.requestIds(1, 11_111);
            assertEq(requestsIds.length, N - 1);
            for (uint256 i; i < N - 1; ++i) {
                assertEq(requestsIds[i], temp.firstRequestId_ + i + 1);
            }
        }
    }

    function test_TriggerWithdrawalRevertInvalidHints(uint256 depositAmount1, uint256 withdrawRequestMaximum_) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum / 2, 50_000 ether);
        withdrawRequestMaximum_ = bound(withdrawRequestMaximum_, 0, type(uint128).max);

        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG);
        vm.deal(address(burner), 0);

        vm.assume(withdrawRequestMaximum_ != withdrawRequestMaximum);

        vm.expectRevert(IETHx_Burner.InvalidHints.selector);
        burner.triggerWithdrawal(withdrawRequestMaximum_);
    }

    function test_TriggerBurn(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMaximum + withdrawRequestMinimum, 50_000 ether);

        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 firstRequestId = burner.triggerWithdrawal(withdrawRequestMaximum);

        uint256 lastRequestId = burner.triggerWithdrawal(withdrawRequestMaximum);

        vm.roll(block.number + IStaderConfig(STADER_CONFIG).getMinBlockDelayToFinalizeWithdrawRequest());
        vm.deal(STAKE_POOLS_MANAGER, 500_000 ether);
        while (IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestIdToFinalize() <= lastRequestId) {
            IUserWithdrawalManager(USER_WITHDRAW_MANAGER).finalizeUserWithdrawalRequest();
        }

        assertEq(address(burner).balance, 0);
        burner.triggerBurn(firstRequestId);
        assertEq(address(burner).balance, 0);

        uint256[] memory requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, 1);
        for (uint256 i; i < requestsIds.length; ++i) {
            assertTrue(firstRequestId != requestsIds[i]);
        }
    }

    function test_TriggerBurnRevertInvalidRequestId(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, withdrawRequestMinimum, 50_000 ether);

        burner = new ETHx_Burner(COLLATERAL, STADER_CONFIG);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 requestId = burner.triggerWithdrawal(withdrawRequestMaximum);

        vm.roll(block.number + IStaderConfig(STADER_CONFIG).getMinBlockDelayToFinalizeWithdrawRequest());
        vm.deal(STAKE_POOLS_MANAGER, 500_000 ether);
        while (IUserWithdrawalManager(USER_WITHDRAW_MANAGER).nextRequestIdToFinalize() <= requestId) {
            IUserWithdrawalManager(USER_WITHDRAW_MANAGER).finalizeUserWithdrawalRequest();
        }

        vm.expectRevert();
        burner.triggerBurn(0);
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
