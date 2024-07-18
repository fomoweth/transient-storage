// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BitMath} from "./BitMath.sol";

/// @title TickBitmap
/// @dev Implementation from https://github.com/Uniswap/v3-core/blob/0.8/contracts/libraries/TickBitmap.sol

library TickBitmap {
	function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
		unchecked {
			wordPos = int16(tick >> 8);
			bitPos = uint8(int8(tick % 256));
		}
	}

	function flipTick(mapping(int16 => uint256) storage self, int24 tick, int24 tickSpacing) internal {
		unchecked {
			require(tick % tickSpacing == 0);

			(int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
			uint256 mask = 1 << bitPos;
			self[wordPos] ^= mask;
		}
	}

	function nextInitializedTickWithinOneWord(
		mapping(int16 => uint256) storage self,
		int24 tick,
		int24 tickSpacing,
		bool lte
	) internal view returns (int24 next, bool initialized) {
		unchecked {
			int24 compressed = tick / tickSpacing;
			if (tick < 0 && tick % tickSpacing != 0) --compressed;

			if (lte) {
				(int16 wordPos, uint8 bitPos) = position(compressed);
				uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
				uint256 masked = self[wordPos] & mask;

				initialized = masked != 0;

				next = initialized
					? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
					: (compressed - int24(uint24(bitPos))) * tickSpacing;
			} else {
				(int16 wordPos, uint8 bitPos) = position(compressed + 1);
				uint256 mask = ~((1 << bitPos) - 1);
				uint256 masked = self[wordPos] & mask;

				initialized = masked != 0;

				next = initialized
					? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
					: (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
			}
		}
	}
}
