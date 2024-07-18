// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title SignedMath
/// @notice Provides functions to handle signed math operations

library SignedMath {
	uint256 internal constant WAD = 1e18;

	function abs(int256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(sar(255, x), add(sar(255, x), x))
		}
	}

	function avg(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := add(and(x, y), shr(1, xor(x, y)))
			z := add(z, and(sar(255, z), xor(x, y)))
		}
	}

	function dist(int256 x, int256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(mul(xor(sub(y, x), sub(x, y)), sgt(x, y)), sub(y, x))
		}
	}

	function ternary(bool condition, int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(y, mul(xor(x, y), iszero(iszero(condition))))
		}
	}

	function max(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), sgt(y, x)))
		}
	}

	function min(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), slt(y, x)))
		}
	}

	function wadMul(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := mul(x, y)

			if iszero(gt(or(iszero(x), eq(sdiv(z, x), y)), lt(not(x), eq(y, shl(255, 1))))) {
				invalid()
			}

			z := sdiv(z, WAD)
		}
	}

	function wadDiv(int256 x, int256 y) internal pure returns (int256 z) {
		assembly ("memory-safe") {
			z := mul(x, WAD)

			if iszero(and(iszero(iszero(y)), eq(sdiv(z, WAD), x))) {
				invalid()
			}

			z := sdiv(mul(x, WAD), y)
		}
	}
}
