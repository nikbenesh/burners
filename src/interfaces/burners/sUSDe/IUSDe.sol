// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IUSDe {
    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) external;
}
