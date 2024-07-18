// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

/// @title PoolGetters
/// @notice Provides getters for Uniswap V3 pools

library PoolGetters {
	function factory(address pool) internal view returns (address poolFactory) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xc45a015500000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			poolFactory := mload(0x00)
		}
	}

	function token0(address pool) internal view returns (Currency currency) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x0dfe168100000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			currency := mload(0x00)
		}
	}

	function token1(address pool) internal view returns (Currency currency) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xd21220a700000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			currency := mload(0x00)
		}
	}

	function fee(address pool) internal view returns (uint24 poolFee) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xddca3f4300000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			poolFee := mload(0x00)
		}
	}

	function liquidity(address pool) internal view returns (uint128 poolLiquidity) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x1a68650200000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			poolLiquidity := mload(0x00)
		}
	}

	function positions(
		address pool,
		bytes32 positionKey
	)
		internal
		view
		returns (
			uint128 positionLiquidity,
			uint256 feeGrowthInside0LastX128,
			uint256 feeGrowthInside1LastX128,
			uint128 tokensOwed0,
			uint128 tokensOwed1
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			let res := add(ptr, 0x24)

			mstore(ptr, 0x514ea4bf00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), positionKey)

			if iszero(staticcall(gas(), pool, ptr, 0x24, res, 0xa0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			positionLiquidity := mload(res)
			feeGrowthInside0LastX128 := mload(add(res, 0x20))
			feeGrowthInside1LastX128 := mload(add(res, 0x40))
			tokensOwed0 := mload(add(res, 0x60))
			tokensOwed1 := mload(add(res, 0x80))
		}
	}

	function slot0(
		address pool
	)
		internal
		view
		returns (
			uint160 sqrtPriceX96,
			int24 tick,
			uint16 observationIndex,
			uint16 observationCardinality,
			uint16 observationCardinalityNext,
			uint8 feeProtocol
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			let res := add(ptr, 0x04)

			mstore(ptr, 0x3850c7bd00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, res, 0xc0)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			sqrtPriceX96 := mload(res)
			tick := mload(add(res, 0x20))
			observationIndex := mload(add(res, 0x40))
			observationCardinality := mload(add(res, 0x60))
			observationCardinalityNext := mload(add(res, 0x80))
			feeProtocol := mload(add(res, 0xa0))
		}
	}

	function getSqrtPriceX96(address pool) internal view returns (uint160 sqrtPriceX96) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x3850c7bd00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pool, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			sqrtPriceX96 := mload(0x00)
		}
	}

	function tickBitmap(address pool, int16 wordPos) internal view returns (uint256 value) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x5339c29600000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), wordPos)

			if iszero(staticcall(gas(), pool, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			value := mload(0x00)
		}
	}

	function ticks(
		address pool,
		int24 tick
	)
		internal
		view
		returns (
			uint128 liquidityGross,
			int128 liquidityNet,
			uint256 feeGrowthOutside0X128,
			uint256 feeGrowthOutside1X128,
			int56 tickCumulativeOutside,
			uint160 secondsPerLiquidityOutsideX128,
			uint32 secondsOutside,
			bool initialized
		)
	{
		assembly ("memory-safe") {
			let ptr := mload(0x40)
			let res := add(ptr, 0x24)

			mstore(ptr, 0xf30dba9300000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), tick)

			if iszero(staticcall(gas(), pool, ptr, 0x24, res, 0x100)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			liquidityGross := mload(res)
			liquidityNet := mload(add(res, 0x20))
			feeGrowthOutside0X128 := mload(add(res, 0x40))
			feeGrowthOutside1X128 := mload(add(res, 0x60))
			tickCumulativeOutside := mload(add(res, 0x80))
			secondsPerLiquidityOutsideX128 := mload(add(res, 0xa0))
			secondsOutside := mload(add(res, 0xc0))
			initialized := mload(add(res, 0xe0))
		}
	}

	function getReserves(address pair) internal view returns (uint256 reserve0, uint256 reserve1) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pair, ptr, 0x04, 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			if or(iszero(mload(0x00)), iszero(mload(0x20))) {
				mstore(0x00, 0xbe5222a3) // InsufficientReserves(address)
				mstore(0x04, pair)
				revert(0x1c, 0x24)
			}

			reserve0 := mload(0x00)
			reserve1 := mload(0x20)
		}
	}

	function price0CumulativeLast(address pair) internal view returns (uint256 price0) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x5909c0d500000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pair, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			price0 := mload(0x00)
		}
	}

	function price1CumulativeLast(address pair) internal view returns (uint256 price1) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x5a3d549300000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pair, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			price1 := mload(0x00)
		}
	}

	function kLast(address pair) internal view returns (uint256 k) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x7464fc3d00000000000000000000000000000000000000000000000000000000)

			if iszero(staticcall(gas(), pair, ptr, 0x04, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			k := mload(0x00)
		}
	}
}
