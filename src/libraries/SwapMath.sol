// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {LiquidityMath} from "./LiquidityMath.sol";
import {Math} from "./Math.sol";
import {PoolGetters} from "./PoolGetters.sol";
import {SafeCast} from "./SafeCast.sol";
import {SqrtPriceMath} from "./SqrtPriceMath.sol";
import {TickBitmap} from "./TickBitmap.sol";
import {TickMath} from "./TickMath.sol";

/// @title SwapMath
/// @dev Modified from https://github.com/Uniswap/v3-core/blob/0.8/contracts/libraries/SwapMath.sol

library SwapMath {
	using PoolGetters for address;
	using SafeCast for uint256;

	struct SwapCache {
		uint8 feeProtocol;
		uint128 liquidityStart;
		uint32 blockTimestamp;
		int56 tickCumulative;
		uint160 secondsPerLiquidityCumulativeX128;
		bool computedLatestObservation;
	}

	struct SwapState {
		int256 amountSpecifiedRemaining;
		int256 amountCalculated;
		uint160 sqrtPriceX96;
		int24 tick;
		uint128 liquidity;
	}

	struct StepComputations {
		uint160 sqrtPriceStartX96;
		int24 tickNext;
		bool initialized;
		uint160 sqrtPriceNextX96;
		uint256 amountIn;
		uint256 amountOut;
		uint256 feeAmount;
	}

	uint160 internal constant MIN_SQRT_PRICE_LIMIT = 4295128740;
	uint160 internal constant MAX_SQRT_PRICE_LIMIT = 1461446703485210103287273052203988822378723970341;

	function computeDeltaAmounts(
		address pool,
		uint24 feePips,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96
	) internal view returns (int256 amount0Delta, int256 amount1Delta) {
		(uint160 sqrtPriceX96, int24 tick, , , , ) = pool.slot0();

		bool isExactInput;
		int24 tickSpacing;

		assembly ("memory-safe") {
			function ternary(condition, x, y) -> z {
				z := xor(y, mul(xor(x, y), iszero(iszero(condition))))
			}

			if iszero(amountSpecified) {
				mstore(0x00, 0x4bc7727e) // AmountSpecifiedZero()
				revert(0x1c, 0x04)
			}

			isExactInput := sgt(amountSpecified, 0)
			tickSpacing := sub(div(feePips, 50), eq(feePips, 100))

			switch iszero(sqrtPriceLimitX96)
			case 0x00 {
				if iszero(
					ternary(
						zeroForOne,
						and(lt(sqrtPriceLimitX96, sqrtPriceX96), gt(sqrtPriceLimitX96, sub(MIN_SQRT_PRICE_LIMIT, 1))),
						and(gt(sqrtPriceLimitX96, sqrtPriceX96), lt(sqrtPriceLimitX96, add(MAX_SQRT_PRICE_LIMIT, 1)))
					)
				) {
					mstore(0x00, 0xc6173ebc) // SqrtPriceLimitOutOfBounds()
					revert(0x1c, 0x04)
				}
			}
			default {
				sqrtPriceLimitX96 := ternary(zeroForOne, MIN_SQRT_PRICE_LIMIT, MAX_SQRT_PRICE_LIMIT)
			}
		}

		SwapState memory state = SwapState({
			amountSpecifiedRemaining: amountSpecified,
			amountCalculated: 0,
			sqrtPriceX96: sqrtPriceX96,
			tick: tick,
			liquidity: pool.liquidity()
		});

		while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
			StepComputations memory step;

			step.sqrtPriceStartX96 = state.sqrtPriceX96;

			(step.tickNext, step.initialized) = TickBitmap.nextInitializedTickWithinOneWord(
				pool,
				state.tick,
				tickSpacing,
				zeroForOne
			);

			if (step.tickNext < TickMath.MIN_TICK) {
				step.tickNext = TickMath.MIN_TICK;
			} else if (step.tickNext > TickMath.MAX_TICK) {
				step.tickNext = TickMath.MAX_TICK;
			}

			step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

			(state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
				state.sqrtPriceX96,
				(zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
					? sqrtPriceLimitX96
					: step.sqrtPriceNextX96,
				state.liquidity,
				state.amountSpecifiedRemaining,
				feePips
			);

			if (isExactInput) {
				unchecked {
					state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
				}

				state.amountCalculated -= step.amountOut.toInt256();
			} else {
				unchecked {
					state.amountSpecifiedRemaining += step.amountOut.toInt256();
				}

				state.amountCalculated += (step.amountIn + step.feeAmount).toInt256();
			}

			if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
				if (step.initialized) {
					(, int128 liquidityNet, , , , , , ) = pool.ticks(step.tickNext);

					unchecked {
						if (zeroForOne) liquidityNet = -liquidityNet;
					}

					state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
				}

				unchecked {
					state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
				}
			} else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
				state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
			}
		}

		unchecked {
			(amount0Delta, amount1Delta) = zeroForOne == isExactInput
				? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
				: (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
		}
	}

	function computeSwapStep(
		uint160 sqrtRatioCurrentX96,
		uint160 sqrtRatioTargetX96,
		uint128 liquidity,
		int256 amountRemaining,
		uint24 feePips
	) internal pure returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) {
		unchecked {
			bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
			bool exactIn = amountRemaining >= 0;

			if (exactIn) {
				uint256 amountRemainingLessFee = Math.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
				amountIn = zeroForOne
					? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
					: SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
				if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
				else
					sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
						sqrtRatioCurrentX96,
						liquidity,
						amountRemainingLessFee,
						zeroForOne
					);
			} else {
				amountOut = zeroForOne
					? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
					: SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
				if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
				else
					sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
						sqrtRatioCurrentX96,
						liquidity,
						uint256(-amountRemaining),
						zeroForOne
					);
			}

			bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

			if (zeroForOne) {
				amountIn = max && exactIn
					? amountIn
					: SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
				amountOut = max && !exactIn
					? amountOut
					: SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
			} else {
				amountIn = max && exactIn
					? amountIn
					: SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
				amountOut = max && !exactIn
					? amountOut
					: SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
			}

			if (!exactIn && amountOut > uint256(-amountRemaining)) {
				amountOut = uint256(-amountRemaining);
			}

			if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
				feeAmount = uint256(amountRemaining) - amountIn;
			} else {
				feeAmount = Math.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
			}
		}
	}
}
