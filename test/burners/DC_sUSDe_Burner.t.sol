// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {DC_sUSDe_Burner} from "src/contracts/burners/DC_sUSDe/DC_sUSDe_Burner.sol";
import {DC_sUSDe_Miniburner} from "src/contracts/burners/DC_sUSDe/DC_sUSDe_Miniburner.sol";

import {IDC_sUSDe_Burner} from "src/interfaces/burners/DC_sUSDe/IDC_sUSDe_Burner.sol";
import {ISUSDe} from "src/interfaces/burners/DC_sUSDe/ISUSDe.sol";

import {IERC20} from "test/mocks/AaveV3Borrow.sol";

import {IDefaultCollateral} from "@symbiotic/collateral/interfaces/defaultCollateral/IDefaultCollateral.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract DC_sUSDe_BurnerTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    DC_sUSDe_Burner burner;

    address public constant COLLATERAL = 0x19d0D8e6294B7a04a2733FE433444704B791939A;
    address public constant SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    address public constant MINTER = 0xe3490297a08d6fC8Da46Edb7B6142E4F461b62D3;
    address public constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address public constant DEFAULT_ADMIN = 0x3B0AAf6e6fCd4a7cEEf8c92C32DFeA9E64dC1862;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        IERC20(SUSDE).approve(COLLATERAL, type(uint256).max);

        vm.deal(address(this), 1_000_000 ether);

        vm.startPrank(IDefaultCollateral(COLLATERAL).limitIncreaser());
        IDefaultCollateral(COLLATERAL).increaseLimit(10_000_000_000 ether);
        vm.stopPrank();

        vm.startPrank(MINTER);
        IUSDe(USDE).mint(address(this), 1_000_000_000 ether);
        vm.stopPrank();

        IERC20(USDE).approve(SUSDE, type(uint256).max);
        ISUSDe(SUSDE).deposit(1_000_000_000 ether, address(this));

        IDefaultCollateral(COLLATERAL).deposit(address(this), 500_000_000 ether);
    }

    function test_Create() public {
        DC_sUSDe_Miniburner implementation = new DC_sUSDe_Miniburner(SUSDE);

        burner = new DC_sUSDe_Burner(COLLATERAL, address(implementation));
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.ASSET(), SUSDE);
        assertEq(burner.USDE(), USDE);
    }

    function test_TriggerWithdrawal(uint256 depositAmount1, uint256 depositAmount2, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(SUSDE).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 250_000_000 ether);
        depositAmount2 = bound(depositAmount2, 1, 250_000_000 ether);

        burner = new DC_sUSDe_Burner(COLLATERAL, address(new DC_sUSDe_Miniburner(SUSDE)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);
        assertEq(IERC20(SUSDE).balanceOf(address(burner)), 0);
        address requestsId = burner.triggerWithdrawal();
        assertTrue(requestsId.code.length > 0);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);
        assertEq(IERC20(SUSDE).balanceOf(address(burner)), 0);

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
        assertEq(IERC20(SUSDE).balanceOf(address(burner)), 0);
        address requestsId2 = burner.triggerWithdrawal();
        assertTrue(requestsId2.code.length > 0);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);
        assertEq(IERC20(SUSDE).balanceOf(address(burner)), 0);

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

    function test_TriggerBurn(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(SUSDE).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new DC_sUSDe_Burner(COLLATERAL, address(new DC_sUSDe_Miniburner(SUSDE)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 usdeAmount = ISUSDe(SUSDE).previewRedeem(depositAmount1);
        address requestsId = burner.triggerWithdrawal();

        vm.warp(block.timestamp + ISUSDe(SUSDE).cooldownDuration());

        uint256 totalSupplyBefore = IERC20(USDE).totalSupply();
        burner.triggerBurn(requestsId);
        assertEq(totalSupplyBefore - IERC20(USDE).totalSupply(), usdeAmount);

        assertEq(burner.requestIdsLength(), 0);
    }

    function test_TriggerBurnRevertInvalidRequestId(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(SUSDE).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new DC_sUSDe_Burner(COLLATERAL, address(new DC_sUSDe_Miniburner(SUSDE)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        burner.triggerWithdrawal();

        vm.warp(block.timestamp + ISUSDe(SUSDE).cooldownDuration());

        vm.expectRevert(IDC_sUSDe_Burner.InvalidRequestId.selector);
        burner.triggerBurn(address(0));
    }

    function test_TriggerWithdrawalRevertNoCooldown(uint256 depositAmount1) public {
        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(SUSDE).setCooldownDuration(0);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new DC_sUSDe_Burner(COLLATERAL, address(new DC_sUSDe_Miniburner(SUSDE)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IDC_sUSDe_Burner.NoCooldown.selector);
        burner.triggerWithdrawal();
    }

    function test_TriggerInstantBurn(uint256 depositAmount1) public {
        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(SUSDE).setCooldownDuration(0);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new DC_sUSDe_Burner(COLLATERAL, address(new DC_sUSDe_Miniburner(SUSDE)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 usdeAmount = ISUSDe(SUSDE).previewRedeem(depositAmount1);

        uint256 totalSupplyBefore = IERC20(USDE).totalSupply();
        burner.triggerInstantBurn();
        assertEq(totalSupplyBefore - IERC20(USDE).totalSupply(), usdeAmount);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), 0);
    }

    function test_TriggerInstantBurnRevertHasCooldown(uint256 depositAmount1, uint24 duration) public {
        duration = uint24(bound(duration, 1, 90 days));

        vm.startPrank(DEFAULT_ADMIN);
        ISUSDe(SUSDE).setCooldownDuration(duration);
        vm.stopPrank();

        depositAmount1 = bound(depositAmount1, 1, 400_000_000 ether);

        burner = new DC_sUSDe_Burner(COLLATERAL, address(new DC_sUSDe_Miniburner(SUSDE)));
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.expectRevert(IDC_sUSDe_Burner.HasCooldown.selector);
        burner.triggerInstantBurn();
    }
}

interface IUSDe {
    function mint(address account, uint256 amount) external;
}
