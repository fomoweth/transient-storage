// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

/// @title PoolAddress
/// @notice Provides functions for deriving a pool/pair address from its factory and salt

library PoolAddress {
	function compute(
		address factory,
		bytes32 initCodeHash,
		Currency currency0,
		Currency currency1,
		uint24 fee
	) internal view returns (address pool) {
		assembly ("memory-safe") {
			if gt(currency0, currency1) {
				let temp := currency0
				currency0 := currency1
				currency1 := temp
			}

			let ptr := mload(0x40)

			mstore(add(ptr, 0x15), currency0)
			mstore(add(ptr, 0x35), currency1)
			mstore(add(ptr, 0x55), fee)

			mstore(ptr, add(hex"ff", shl(0x58, factory)))
			mstore(add(ptr, 0x15), keccak256(add(ptr, 0x15), 0x60))
			mstore(add(ptr, 0x35), initCodeHash)

			pool := and(keccak256(ptr, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

			// revert if pool at computed address hasn't deployed yet
			if iszero(extcodesize(pool)) {
				mstore(0x00, 0x3f36c1ab) // PoolNotExists(address)
				mstore(0x20, pool)
				revert(0x1c, 0x24)
			}
		}
	}

	function compute(
		address factory,
		bytes32 initCodeHash,
		Currency currency0,
		Currency currency1
	) internal view returns (address pair) {
		assembly ("memory-safe") {
			if gt(currency0, currency1) {
				let temp := currency0
				currency0 := currency1
				currency1 := temp
			}

			let ptr := mload(0x40)

			mstore(ptr, shl(0x60, currency0))
			mstore(add(ptr, 0x14), shl(0x60, currency1))

			let salt := keccak256(ptr, 0x28)

			mstore(ptr, add(hex"ff", shl(0x58, factory)))
			mstore(add(ptr, 0x15), salt)
			mstore(add(ptr, 0x35), initCodeHash)

			pair := and(keccak256(ptr, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

			// revert if pair at computed address hasn't deployed yet
			if iszero(extcodesize(pair)) {
				mstore(0x00, 0xcc644557) // PairNotExists(address)
				mstore(0x20, pair)
				revert(0x1c, 0x24)
			}
		}
	}
}
