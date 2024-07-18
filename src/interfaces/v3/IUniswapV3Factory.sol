// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

interface IUniswapV3Factory {
	event OwnerChanged(address indexed oldOwner, address indexed newOwner);

	event PoolCreated(
		Currency indexed currency0,
		Currency indexed currency1,
		uint24 indexed fee,
		int24 tickSpacing,
		address pool
	);

	event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

	function owner() external view returns (address);

	function feeAmountTickSpacing(uint24 fee) external view returns (int24);

	function getPool(Currency currencyA, Currency currencyB, uint24 fee) external view returns (address pool);

	function createPool(Currency currencyA, Currency currencyB, uint24 fee) external returns (address pool);

	function setOwner(address owner) external;

	function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}
