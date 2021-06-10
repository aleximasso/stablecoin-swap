// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;


contract MockOracle {
    function update() external returns (bool success) {
        return true;
    }

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut) {
        return (2000 * 10**6);   // 1 Token = 2000 USDT
    }
}
