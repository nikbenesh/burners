// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IUSDe {
    function minter() external view returns (address);

    function mint(address account, uint256 amount) external;

    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) external;
}
