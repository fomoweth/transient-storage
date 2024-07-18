// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {FixedPoint128} from "./FixedPoint128.sol";
import {LiquidityMath} from "./LiquidityMath.sol";
import {Math} from "./Math.sol";

/// @title Position
/// @dev Implementation from https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/Position.sol

library Position {
	struct Info {
		uint128 liquidity;
		uint256 feeGrowthInside0LastX128;
		uint256 feeGrowthInside1LastX128;
		uint128 tokensOwed0;
		uint128 tokensOwed1;
	}

	function get(
		mapping(bytes32 => Info) storage self,
		address owner,
		int24 tickLower,
		int24 tickUpper
	) internal view returns (Position.Info storage position) {
		position = self[keccak256(abi.encodePacked(owner, tickLower, tickUpper))];
	}

	function update(
		Info storage self,
		int128 liquidityDelta,
		uint256 feeGrowthInside0X128,
		uint256 feeGrowthInside1X128
	) internal {
		Info memory _self = self;

		uint128 liquidityNext;

		if (liquidityDelta == 0) {
			require(_self.liquidity > 0);
			liquidityNext = _self.liquidity;
		} else {
			liquidityNext = LiquidityMath.addDelta(_self.liquidity, liquidityDelta);
		}

		uint128 tokensOwed0;
		uint128 tokensOwed1;

		unchecked {
			tokensOwed0 = uint128(
				Math.mulDiv(feeGrowthInside0X128 - _self.feeGrowthInside0LastX128, _self.liquidity, FixedPoint128.Q128)
			);
			tokensOwed1 = uint128(
				Math.mulDiv(feeGrowthInside1X128 - _self.feeGrowthInside1LastX128, _self.liquidity, FixedPoint128.Q128)
			);

			if (liquidityDelta != 0) self.liquidity = liquidityNext;
			self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
			self.feeGrowthInside1LastX128 = feeGrowthInside1X128;

			if (tokensOwed0 > 0 || tokensOwed1 > 0) {
				self.tokensOwed0 += tokensOwed0;
				self.tokensOwed1 += tokensOwed1;
			}
		}
	}
}
