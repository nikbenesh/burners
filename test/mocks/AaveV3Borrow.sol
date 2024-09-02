// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract AaveV3Borrow {
    IPool private constant POOL = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    function supplyAndBorrow(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut) external {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(POOL), amountIn);

        POOL.supply(tokenIn, amountIn, address(this), 0);
        POOL.borrow(tokenOut, amountOut, 2, 0, address(this));

        IERC20(tokenOut).transfer(msg.sender, amountOut);
    }
}

/// @title Aave V3 Pool interface
/// @notice Interface for the Aave V3 Pool
interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;
}

/// @title ERC20 interface
/// @notice Interface for the EIP20 standard token.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(
        address account
    ) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/// @title WETH interface
/// @notice Interface for the WETH token.
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(
        uint256 amount
    ) external;
}
