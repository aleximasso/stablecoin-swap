// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IERC20Mintable is IERC20 {
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) external;
    /**

     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function burn(uint256 amount) external;
}