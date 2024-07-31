// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {rETH_Burner} from "src/contracts/burners/rETH_Burner.sol";

import {IrETH_Burner} from "src/interfaces/burners/rETH/IrETH_Burner.sol";
import {IRocketTokenRETH} from "src/interfaces/burners/rETH/IRocketTokenRETH.sol";

import {AaveV3Borrow, IERC20, IWETH} from "test/mocks/AaveV3Borrow.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract rETH_BurnerTest is Test {
    IWETH private weth = IWETH(WETH);

    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    AaveV3Borrow private aave;

    rETH_Burner burner;

    address public constant COLLATERAL = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant ROCKET_DEPOSIT_POOL = 0xDD3f50F8A6CafbE9b31a427582963f465E745AF8;
    address public constant ROCKET_VAULT = 0x3bDC69C4E5e13E52A65f5583c23EFB9636b469d6;

    function setUp() public {
        uint256 mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
        vm.selectFork(mainnetFork);

        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        aave = new AaveV3Borrow();
        weth.approve(address(aave), type(uint256).max);

        vm.deal(address(this), 1_000_000 ether);
        weth.deposit{value: 500_000 ether}();
        uint256 amountOut = 15_000 ether;
        aave.supplyAndBorrow(WETH, 500_000 ether, COLLATERAL, amountOut);

        vm.startPrank(ROCKET_DEPOSIT_POOL);
        IRocketTokenRETH(COLLATERAL).mint(150_000 ether, address(this));
        vm.stopPrank();
    }

    function test_Create() public {
        burner = new rETH_Burner(COLLATERAL);
        vm.deal(address(burner), 0);

        assertEq(burner.COLLATERAL(), COLLATERAL);
    }

    function test_TriggerBurn(uint256 depositAmount1, uint256 burnAmount1, uint256 burnAmount2) public {
        depositAmount1 = bound(depositAmount1, 1, 100_000 ether);
        burnAmount1 = bound(burnAmount1, 1, depositAmount1);
        burnAmount2 = bound(burnAmount2, 1, depositAmount1);

        burner = new rETH_Burner(COLLATERAL);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.assume(
            IRocketTokenRETH(COLLATERAL).getEthValue(burnAmount1) <= IRocketTokenRETH(COLLATERAL).getTotalCollateral()
        );
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1);
        assertEq(address(burner).balance, 0);
        burner.triggerBurn(burnAmount1);
        assertEq(address(burner).balance, 0);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1 - burnAmount1);

        vm.assume(
            IRocketTokenRETH(COLLATERAL).getEthValue(burnAmount2) <= IRocketTokenRETH(COLLATERAL).getTotalCollateral()
                && burnAmount2 <= depositAmount1 - burnAmount1
        );
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1 - burnAmount1);
        assertEq(address(burner).balance, 0);
        burner.triggerBurn(burnAmount2);
        assertEq(address(burner).balance, 0);
        assertEq(IERC20(COLLATERAL).balanceOf(address(burner)), depositAmount1 - burnAmount1 - burnAmount2);
    }

    function test_TriggerBurnRevert(uint256 depositAmount1, uint256 burnAmount1) public {
        depositAmount1 = bound(depositAmount1, 1, 100_000 ether);
        burnAmount1 = bound(burnAmount1, 1, type(uint256).max);

        burner = new rETH_Burner(COLLATERAL);
        vm.deal(address(burner), 0);

        IERC20(COLLATERAL).transfer(address(burner), depositAmount1);

        vm.assume(
            burnAmount1 > depositAmount1
                || IRocketTokenRETH(COLLATERAL).getEthValue(burnAmount1) > IRocketTokenRETH(COLLATERAL).getTotalCollateral()
        );

        vm.expectRevert();
        burner.triggerBurn(burnAmount1);
    }
}
