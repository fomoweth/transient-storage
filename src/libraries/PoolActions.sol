// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PoolActions
/// @notice Provides functions to perform swap on Uniswap V2 & V3 pools

library PoolActions {
	// V3

	function mint(
		address pool,
		address recipient,
		int24 tickLower,
		int24 tickUpper,
		uint128 amount,
		bytes calldata data
	) internal returns (uint256 amount0, uint256 amount1) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x3c8a7d8d00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), recipient)
			mstore(add(ptr, 0x24), tickLower)
			mstore(add(ptr, 0x44), tickUpper)
			mstore(add(ptr, 0x64), amount)
			mstore(add(ptr, 0x84), 0xa0)
			mstore(add(ptr, 0xa4), data.length)
			calldatacopy(add(ptr, 0xc4), data.offset, data.length)

			if iszero(call(gas(), pool, 0x00, ptr, add(0xc4, data.length), 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amount0 := mload(0x00)
			amount1 := mload(0x20)
		}
	}

	function collect(
		address pool,
		address recipient,
		int24 tickLower,
		int24 tickUpper,
		uint128 amount0Requested,
		uint128 amount1Requested
	) internal returns (uint128 amount0, uint128 amount1) {
		assembly ("memory-safe") {
			if iszero(amount0Requested) {
				amount0Requested := sub(shl(128, 1), 1)
			}

			if iszero(amount1Requested) {
				amount1Requested := sub(shl(128, 1), 1)
			}

			let ptr := mload(0x40)

			mstore(ptr, 0x4f1eb3d800000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), recipient)
			mstore(add(ptr, 0x24), tickLower)
			mstore(add(ptr, 0x44), tickUpper)
			mstore(add(ptr, 0x64), amount0Requested)
			mstore(add(ptr, 0x84), amount1Requested)

			if iszero(call(gas(), pool, 0x00, ptr, 0xa4, 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amount0 := mload(0x00)
			amount1 := mload(0x20)
		}
	}

	function burn(
		address pool,
		int24 tickLower,
		int24 tickUpper,
		uint128 amount
	) internal returns (uint256 amount0, uint256 amount1) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0xa34123a700000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), tickLower)
			mstore(add(ptr, 0x24), tickUpper)
			mstore(add(ptr, 0x44), amount)

			if iszero(call(gas(), pool, 0x00, ptr, 0x64, 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amount0 := mload(0x00)
			amount1 := mload(0x20)
		}
	}

	function swap(
		address pool,
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bytes calldata data
	) internal returns (int256 amount0Delta, int256 amount1Delta) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x128acb0800000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), recipient)
			mstore(add(ptr, 0x24), zeroForOne)
			mstore(add(ptr, 0x44), amountSpecified)
			mstore(add(ptr, 0x64), sqrtPriceLimitX96)
			mstore(add(ptr, 0x84), 0xa0)
			mstore(add(ptr, 0xa4), data.length)
			calldatacopy(add(ptr, 0xc4), data.offset, data.length)

			if iszero(call(gas(), pool, 0x00, ptr, add(0xc4, data.length), 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amount0Delta := mload(0x00)
			amount1Delta := mload(0x20)
		}
	}

	function flash(address pool, address recipient, uint256 amount0, uint256 amount1, bytes calldata data) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x490e6cbc00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), recipient)
			mstore(add(ptr, 0x24), amount0)
			mstore(add(ptr, 0x44), amount1)
			mstore(add(ptr, 0x64), 0x80)
			mstore(add(ptr, 0x84), data.length)
			calldatacopy(add(ptr, 0xa4), data.offset, data.length)

			if iszero(call(gas(), pool, 0x00, ptr, add(0xa4, data.length), 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}

	// V2

	function mint(address pair, address recipient) internal returns (uint256 liquidity) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x6a62784200000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), recipient)

			if iszero(call(gas(), pair, 0x00, ptr, 0x24, 0x00, 0x20)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			liquidity := mload(0x00)
		}
	}

	function burn(address pair, address recipient) internal returns (uint256 amount0, uint256 amount1) {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x89afcb4400000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), recipient)

			if iszero(call(gas(), pair, 0x00, ptr, 0x24, 0x00, 0x40)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			amount0 := mload(0x00)
			amount1 := mload(0x20)
		}
	}

	function swap(
		address pair,
		uint256 amount0Out,
		uint256 amount1Out,
		address recipient,
		bytes calldata data
	) internal {
		assembly ("memory-safe") {
			let ptr := mload(0x40)

			mstore(ptr, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
			mstore(add(ptr, 0x04), amount0Out)
			mstore(add(ptr, 0x24), amount1Out)
			mstore(add(ptr, 0x44), recipient)
			mstore(add(ptr, 0x64), 0x80)
			mstore(add(ptr, 0x84), data.length)
			calldatacopy(add(ptr, 0xa4), data.offset, data.length)

			if iszero(call(gas(), pair, 0x00, ptr, add(0xa4, data.length), 0x00, 0x00)) {
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}
		}
	}
}
