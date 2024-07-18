// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

interface IUniswapV3PoolDeployer {
	function parameters() external view returns (Currency currency0, Currency currency1, uint24 fee, int24 tickSpacing);
}
