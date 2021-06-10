// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;


// Interface for helpers/UniswapOracle.sol
interface IUniswapOracle {
    function update() external returns (bool success);
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}