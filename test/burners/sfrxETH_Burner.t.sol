// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {sfrxETH_Burner} from "src/contracts/burners/sfrxETH_Burner.sol";

import {IFraxEtherRedemptionQueue} from "src/interfaces/burners/sfrxETH/IFraxEtherRedemptionQueue.sol";
import {IsfrxETH_Burner} from "src/interfaces/burners/sfrxETH/IsfrxETH_Burner.sol";
import {IUintRequests} from "src/interfaces/IUintRequests.sol";

import {IERC20} from "test/mocks/AaveV3Borrow.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract sfrxETH_BurnerTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    sfrxETH_Burner burner;

    address public constant COLLATERAL = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address public constant FRXETH = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public constant FRAX_ETHER_REDEMPTION_QUEUE = 0x82bA8da44Cd5261762e629dd5c605b17715727bd;
    address public constant FRXETH_MINTER = 0xbAFA44EFE7901E04E39Dad13167D089C559c1138;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vm.deal(address(this), 1_000_000 ether);

        vm.startPrank(FRXETH_MINTER);
        IFrxETH(FRXETH).minter_mint(address(this), 500_000 ether);
        vm.stopPrank();

        IERC20(FRXETH).approve(COLLATERAL, type(uint256).max);
        ISfrxETH(COLLATERAL).deposit(500_000 ether, address(this));
    }

    function test_Create() public {
        burner = new sfrxETH_Burner(COLLATERAL, FRAX_ETHER_REDEMPTION_QUEUE);
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
        assertEq(burner.FRAX_ETHER_REDEMPTION_QUEUE(), FRAX_ETHER_REDEMPTION_QUEUE);
        assertEq(IERC20(COLLATERAL).allowance(address(burner), FRAX_ETHER_REDEMPTION_QUEUE), type(uint256).max);
    }

    function test_TriggerWithdrawal(uint256 depositAmount1, uint256 depositAmount2) public {
        depositAmount1 = bound(depositAmount1, 1, 50_000 ether);
        depositAmount2 = bound(depositAmount2, 1, 50_000 ether);

        burner = new sfrxETH_Burner(COLLATERAL, FRAX_ETHER_REDEMPTION_QUEUE);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);
        (uint256 nextRequestId,,,) = IFraxEtherRedemptionQueue(FRAX_ETHER_REDEMPTION_QUEUE).redemptionQueueState();
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
        (nextRequestId,,,) = IFraxEtherRedemptionQueue(FRAX_ETHER_REDEMPTION_QUEUE).redemptionQueueState();
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

    function test_TriggerBurn(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 1, 10_000 ether);

        burner = new sfrxETH_Burner(COLLATERAL, FRAX_ETHER_REDEMPTION_QUEUE);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        uint256 requestsId = burner.triggerWithdrawal();

        vm.deal(FRAX_ETHER_REDEMPTION_QUEUE, 1_000_000 ether);

        (, uint256 queueLengthSecs,,) = IFraxEtherRedemptionQueue(FRAX_ETHER_REDEMPTION_QUEUE).redemptionQueueState();

        vm.warp(block.timestamp + queueLengthSecs);

        assertEq(address(burner).balance, 0);
        burner.triggerBurn(requestsId);
        assertEq(address(burner).balance, 0);

        assertEq(burner.requestIdsLength(), 0);
    }

    function test_TriggerBurnRevertInvalidRequestId(uint256 depositAmount1) public {
        depositAmount1 = bound(depositAmount1, 1, 10_000 ether);

        burner = new sfrxETH_Burner(COLLATERAL, FRAX_ETHER_REDEMPTION_QUEUE);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        burner.triggerWithdrawal();

        vm.deal(FRAX_ETHER_REDEMPTION_QUEUE, 1_000_000 ether);

        (, uint256 queueLengthSecs,,) = IFraxEtherRedemptionQueue(FRAX_ETHER_REDEMPTION_QUEUE).redemptionQueueState();

        vm.warp(block.timestamp + queueLengthSecs);

        vm.expectRevert(IUintRequests.InvalidRequestId.selector);
        burner.triggerBurn(0);
    }
}

interface IFrxETH {
    // This function is what other minters will call to mint new tokens
    function minter_mint(address m_address, uint256 m_amount) external;
}

interface ISfrxETH {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
}
