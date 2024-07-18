// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {SelfDestruct} from "src/contracts/SelfDestruct.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SelfDestructTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    SelfDestruct selfDestruct;

    function setUp() public {
        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");
    }

    function test_Create() public {
        uint256 balanceBefore = address(this).balance;
        selfDestruct = new SelfDestruct{value: 100 ether}();
        assertEq(balanceBefore - address(this).balance, 100 ether);
        assertEq(address(selfDestruct).balance, 0);
    }
}
