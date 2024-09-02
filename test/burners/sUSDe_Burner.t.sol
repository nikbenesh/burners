// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {sUSDe_Burner} from "../../src/contracts/burners/sUSDe/sUSDe_Burner.sol";
import {sUSDe_Miniburner} from "../../src/contracts/burners/sUSDe/sUSDe_Miniburner.sol";

import {IsUSDe_Burner} from "../../src/interfaces/burners/sUSDe/IsUSDe_Burner.sol";
import {ISUSDe} from "../../src/interfaces/burners/sUSDe/ISUSDe.sol";
import {IUSDe} from "../../src/interfaces/burners/sUSDe/IUSDe.sol";
import {IEthenaMinting} from "../../src/interfaces/burners/sUSDe/IEthenaMinting.sol";
import {IAddressRequests} from "../../src/interfaces/IAddressRequests.sol";

import {IERC20} from "test/mocks/AaveV3Borrow.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract sUSDe_BurnerTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    sUSDe_Burner burner;

    address public constant COLLATERAL = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    address public constant MINTER = 0xe3490297a08d6fC8Da46Edb7B6142E4F461b62D3;
    address public constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address public constant DEFAULT_ADMIN = 0x3B0AAf6e6fCd4a7cEEf8c92C32DFeA9E64dC1862;
    address public constant REDEEMER = 0xD0899998CCEB5B3df5cdcFaAdd43e53B8e1d553e;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vm.deal(address(this), 1_000_000 ether);

        vm.startPrank(MINTER);
        IUSDe(USDE).mint(address(this), 1_000_000_000 ether);
        vm.stopPrank();

        IERC20(USDE).approve(COLLATERAL, type(uint256).max);
        ISUSDe(COLLATERAL).deposit(1_000_000_000 ether, address(this));
    }

    function test_Create() public {
        sUSDe_Miniburner implementation = new sUSDe_Miniburner(COLLATERAL);

        burner = new sUSDe_Burner(COLLATERAL, address(implementation));
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.USDE(), USDE);
        assertEq(IERC20(USDE).allowance(address(burner), IUSDe(USDE).minter()), type(uint256).max);
    }

    function test_TriggerWithdrawal(uint256 depositAmount1, uint256 depositAmount2, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 250_000_000 ether);
        depositAmount2 = bound(depositAmount2, 1, 250_000_000 ether);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);
        address requestsId = burner.triggerWithdrawal();
        assertTrue(requestsId.code.length > 0);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);

        assertEq(burner.requestIdsLength(), 1);
        address[] memory requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, 1);
        assertEq(requestsIds[0], requestsId);
        requestsIds = burner.requestIds(0, 0);
        assertEq(requestsIds.length, 0);
        requestsIds = burner.requestIds(0, 1);
        assertEq(requestsIds.length, 1);
        assertEq(requestsIds[0], requestsId);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount2);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount2);
        address requestsId2 = burner.triggerWithdrawal();
        assertTrue(requestsId2.code.length > 0);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);

        assertEq(burner.requestIdsLength(), 2);
        requestsIds = burner.requestIds(0, type(uint256).max);
        assertEq(requestsIds.length, 2);
        assertEq(requestsIds[0], requestsId);
        assertEq(requestsIds[1], requestsId2);
        requestsIds = burner.requestIds(0, 0);
        assertEq(requestsIds.length, 0);
        requestsIds = burner.requestIds(0, 2);
        assertEq(requestsIds.length, 2);
        assertEq(requestsIds[0], requestsId);
        assertEq(requestsIds[1], requestsId2);
    }

    function test_TriggerClaim(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 usdeAmount = ISUSDe(COLLATERAL).previewRedeem(depositAmount1);
        address requestsId = burner.triggerWithdrawal();

        vm.warp(block.timestamp + ISUSDe(COLLATERAL).cooldownDuration());

        uint256 balanceBefore = IERC20(USDE).balanceOf(address(burner));
        burner.triggerClaim(requestsId);
        assertEq(IERC20(USDE).balanceOf(address(burner)) - balanceBefore, usdeAmount);

        assertEq(burner.requestIdsLength(), 0);
    }

    function test_TriggerClaimRevertInvalidRequestId(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        burner.triggerWithdrawal();

        vm.warp(block.timestamp + ISUSDe(COLLATERAL).cooldownDuration());

        vm.expectRevert(IAddressRequests.InvalidRequestId.selector);
        burner.triggerClaim(address(0));
    }

    function test_TriggerClaimRevertNoCooldown(
        uint256 depositAmount1
    ) public {
        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(0);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IsUSDe_Burner.NoCooldown.selector);
        burner.triggerWithdrawal();
    }

    function test_TriggerInstantClaim(
        uint256 depositAmount1
    ) public {
        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(0);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 usdeAmount = ISUSDe(COLLATERAL).previewRedeem(depositAmount1);

        uint256 balanceBefore = IERC20(USDE).balanceOf(address(burner));
        burner.triggerInstantClaim();
        assertEq(IERC20(USDE).balanceOf(address(burner)) - balanceBefore, usdeAmount);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);
    }

    function test_TriggerInstantClaimRevertHasCooldown(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IsUSDe_Burner.HasCooldown.selector);
        burner.triggerInstantClaim();
    }

    function test_TriggerBurn1(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1e9, IERC20(USDT).balanceOf(IUSDe(USDE).minter()) * 1e12 / 2);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 usdeAmount = ISUSDe(COLLATERAL).previewRedeem(depositAmount1);

        vm.assume(
            usdeAmount >= 1e12
                && usdeAmount
                    <= Math.min(
                        IEthenaMinting(IUSDe(USDE).minter()).tokenConfig(USDT).maxRedeemPerBlock
                            - IEthenaMinting(IUSDe(USDE).minter()).totalPerBlockPerAsset(block.number, USDT).redeemedPerBlock,
                        IEthenaMinting(IUSDe(USDE).minter()).globalConfig().globalMaxRedeemPerBlock
                            - IEthenaMinting(IUSDe(USDE).minter()).totalPerBlock(block.number).redeemedPerBlock
                    )
        );

        address requestsId = burner.triggerWithdrawal();

        vm.warp(block.timestamp + ISUSDe(COLLATERAL).cooldownDuration());

        burner.triggerClaim(requestsId);

        IEthenaMinting.Order memory order = IEthenaMinting.Order({
            order_id: "order_id",
            order_type: IEthenaMinting.OrderType.REDEEM,
            expiry: uint120(block.timestamp + 1 days),
            nonce: uint128(1),
            benefactor: address(burner),
            beneficiary: address(burner),
            collateral_asset: USDT,
            collateral_amount: uint128(usdeAmount / 1e12),
            usde_amount: uint128(usdeAmount)
        });

        IEthenaMinting.Signature memory signature = IEthenaMinting.Signature({
            signature_type: IEthenaMinting.SignatureType.EIP1271,
            signature_bytes: abi.encode(order)
        });

        vm.startPrank(DEFAULT_ADMIN);
        IEthenaMinting(IUSDe(USDE).minter()).addWhitelistedBenefactor(address(burner));
        vm.stopPrank();

        uint256 balanceBefore = IERC20(USDE).balanceOf(address(burner));
        uint256 balanceBefore2 = IERC20(USDT).balanceOf(address(burner));

        vm.startPrank(REDEEMER);
        IEthenaMinting(IUSDe(USDE).minter()).redeem(order, signature);
        vm.stopPrank();

        assertEq(balanceBefore - IERC20(USDE).balanceOf(address(burner)), usdeAmount);
        assertEq(IERC20(USDT).balanceOf(address(burner)) - balanceBefore2, usdeAmount / 1e12);

        balanceBefore = IERC20(USDT).balanceOf(address(burner));
        balanceBefore2 = IERC20(USDT).balanceOf(address(0xdEaD));

        burner.triggerBurn(USDT);

        assertEq(balanceBefore - IERC20(USDT).balanceOf(address(burner)), usdeAmount / 1e12);
        assertEq(IERC20(USDT).balanceOf(address(0xdEaD)) - balanceBefore2, usdeAmount / 1e12);
    }

    function test_TriggerBurn2(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1e9, IERC20(USDT).balanceOf(IUSDe(USDE).minter()) * 1e12 / 2);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        vm.deal(address(burner), depositAmount1);

        uint256 balanceBefore = address(burner).balance;
        burner.triggerBurn(address(0));
        assertEq(balanceBefore - address(burner).balance, depositAmount1);
    }

    function test_TriggerBurnRevertInvalidAsset1(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1e9, IERC20(USDT).balanceOf(IUSDe(USDE).minter()) * 1e12 / 2);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IsUSDe_Burner.InvalidAsset.selector);
        burner.triggerBurn(COLLATERAL);
    }

    function test_TriggerBurnRevertInvalidAsset2(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1e9, IERC20(USDT).balanceOf(IUSDe(USDE).minter()) * 1e12 / 2);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 usdeAmount = ISUSDe(COLLATERAL).previewRedeem(depositAmount1);

        vm.assume(
            usdeAmount >= 1e12
                && usdeAmount
                    <= Math.min(
                        IEthenaMinting(IUSDe(USDE).minter()).tokenConfig(USDT).maxRedeemPerBlock
                            - IEthenaMinting(IUSDe(USDE).minter()).totalPerBlockPerAsset(block.number, USDT).redeemedPerBlock,
                        IEthenaMinting(IUSDe(USDE).minter()).globalConfig().globalMaxRedeemPerBlock
                            - IEthenaMinting(IUSDe(USDE).minter()).totalPerBlock(block.number).redeemedPerBlock
                    )
        );

        address requestsId = burner.triggerWithdrawal();

        vm.warp(block.timestamp + ISUSDe(COLLATERAL).cooldownDuration());

        burner.triggerClaim(requestsId);

        IEthenaMinting.Order memory order = IEthenaMinting.Order({
            order_id: "order_id",
            order_type: IEthenaMinting.OrderType.REDEEM,
            expiry: uint120(block.timestamp + 1 days),
            nonce: uint128(1),
            benefactor: address(burner),
            beneficiary: address(burner),
            collateral_asset: USDT,
            collateral_amount: uint128(usdeAmount / 1e12),
            usde_amount: uint128(usdeAmount)
        });

        IEthenaMinting.Signature memory signature = IEthenaMinting.Signature({
            signature_type: IEthenaMinting.SignatureType.EIP1271,
            signature_bytes: abi.encode(order)
        });

        vm.startPrank(DEFAULT_ADMIN);
        IEthenaMinting(IUSDe(USDE).minter()).addWhitelistedBenefactor(address(burner));
        vm.stopPrank();

        vm.startPrank(REDEEMER);
        IEthenaMinting(IUSDe(USDE).minter()).redeem(order, signature);
        vm.stopPrank();

        vm.expectRevert(IsUSDe_Burner.InvalidAsset.selector);
        burner.triggerBurn(USDE);
    }

    function test_ApproveUSDeMinter(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1e9, IERC20(USDT).balanceOf(IUSDe(USDE).minter()) * 1e12 / 2);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        vm.startPrank(address(burner));
        IERC20(USDE).approve(MINTER, 0);
        vm.stopPrank();

        assertEq(IERC20(USDE).allowance(address(burner), IUSDe(USDE).minter()), 0);

        burner.approveUSDeMinter();

        assertEq(IERC20(USDE).allowance(address(burner), IUSDe(USDE).minter()), type(uint256).max);
    }

    function test_ApproveUSDeMinterRevertSufficientAllowance(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(COLLATERAL).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1e9, IERC20(USDT).balanceOf(IUSDe(USDE).minter()) * 1e12 / 2);

        burner = new sUSDe_Burner(COLLATERAL, address(new sUSDe_Miniburner(COLLATERAL)));
        vm.deal(address(burner), 0);

        vm.startPrank(address(burner));
        IERC20(USDE).approve(MINTER, 0);
        vm.stopPrank();

        burner.approveUSDeMinter();

        vm.expectRevert(IsUSDe_Burner.SufficientApproval.selector);
        burner.approveUSDeMinter();
    }
}
