// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";
import {IUniswapV2ERC20} from "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
	event Mint(address indexed sender, uint256 amount0, uint256 amount1);

	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);

	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed recipient
	);

	event Sync(uint112 reserve0, uint112 reserve1);

	error Forbidden();

	error K();

	error InsufficientLiquidity();

	error InsufficientLiquidityMinted();

	error InsufficientLiquidityBurned();

	error InsufficientInputAmount();

	error InsufficientOutputAmount();

	function mint(address recipient) external returns (uint256 liquidity);

	function burn(address recipient) external returns (uint256 amount0, uint256 amount1);

	function swap(uint256 amount0Out, uint256 amount1Out, address recipient, bytes calldata data) external;

	function skim(address recipient) external;

	function sync() external;

	function initialize(Currency token0, Currency token1) external;

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (Currency);

	function token1() external view returns (Currency);

	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);
}
