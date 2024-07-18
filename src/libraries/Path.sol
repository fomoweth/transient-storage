// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

/// @title Path
/// @dev Modified from https://github.com/Uniswap/universal-router/blob/main/contracts/modules/uniswap/v3/V3Path.sol

library Path {
	uint256 internal constant ADDR_SIZE = 20;
	uint256 internal constant FEE_SIZE = 3;
	uint256 internal constant NEXT_OFFSET = 23; // ADDR_SIZE + FEE_SIZE
	uint256 internal constant POP_OFFSET = 43; // NEXT_OFFSET + ADDR_SIZE
	uint256 internal constant MULTIPLE_POOLS_MIN_LENGTH = 66; // POP_OFFSET + NEXT_OFFSET

	function isFinalSwap(bytes calldata path) internal pure returns (bool b) {
		assembly ("memory-safe") {
			b := eq(path.length, POP_OFFSET)
		}
	}

	function hasMultiplePools(bytes calldata path) internal pure returns (bool b) {
		assembly ("memory-safe") {
			b := iszero(lt(path.length, MULTIPLE_POOLS_MIN_LENGTH))
		}
	}

	function numPools(bytes calldata path) internal pure returns (uint256 n) {
		assembly ("memory-safe") {
			if iszero(lt(path.length, POP_OFFSET)) {
				if iszero(iszero(mod(sub(path.length, ADDR_SIZE), NEXT_OFFSET))) {
					mstore(0x00, 0xcd608bfe) // InvalidPathLength()
					revert(0x1c, 0x04)
				}

				n := div(sub(path.length, ADDR_SIZE), NEXT_OFFSET)
			}
		}
	}

	function decodeFirstPool(
		bytes calldata path
	) internal pure returns (Currency currencyIn, Currency currencyOut, uint24 fee) {
		assembly ("memory-safe") {
			if lt(path.length, POP_OFFSET) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			let firstWord := calldataload(path.offset)
			currencyIn := shr(0x60, firstWord)
			fee := and(shr(0x48, firstWord), 0xffffff)
			currencyOut := shr(0x60, calldataload(add(path.offset, NEXT_OFFSET)))
		}
	}

	function decodeLastPool(
		bytes calldata path
	) internal pure returns (Currency currencyIn, Currency currencyOut, uint24 fee) {
		assembly ("memory-safe") {
			if lt(path.length, POP_OFFSET) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			let firstWord := calldataload(add(path.offset, sub(path.length, POP_OFFSET)))
			currencyIn := shr(0x60, firstWord)
			fee := and(shr(0x48, firstWord), 0xffffff)
			currencyOut := shr(0x60, calldataload(add(path.offset, sub(path.length, ADDR_SIZE))))
		}
	}

	function decodeFirstCurrency(bytes calldata path) internal pure returns (Currency currency) {
		assembly ("memory-safe") {
			currency := shr(0x60, calldataload(path.offset))
		}
	}

	function decodeLastCurrency(bytes calldata path) internal pure returns (Currency currency) {
		assembly ("memory-safe") {
			currency := shr(0x60, calldataload(add(path.offset, sub(path.length, ADDR_SIZE))))
		}
	}

	function getFirstPool(bytes calldata path) internal pure returns (bytes calldata res) {
		assembly ("memory-safe") {
			res.offset := path.offset
			res.length := POP_OFFSET
		}
	}

	function getLastPool(bytes calldata path) internal pure returns (bytes calldata res) {
		assembly ("memory-safe") {
			res.offset := add(path.offset, sub(path.length, POP_OFFSET))
			res.length := POP_OFFSET
		}
	}

	function skipCurrency(bytes calldata path) internal pure returns (bytes calldata res) {
		assembly ("memory-safe") {
			res.offset := add(path.offset, NEXT_OFFSET)
			res.length := sub(path.length, NEXT_OFFSET)
		}
	}
}
