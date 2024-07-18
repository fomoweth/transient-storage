// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title LiquidityMath
/// @dev Implementation from https://github.com/Uniswap/v4-core/blob/main/src/libraries/LiquidityMath.sol

library LiquidityMath {
	function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
		assembly ("memory-safe") {
			z := add(x, y)

			if shr(128, z) {
				mstore(0x00, 0x93dafdf1) // SafeCastOverflow()
				revert(0x1c, 0x04)
			}
		}
	}
}
