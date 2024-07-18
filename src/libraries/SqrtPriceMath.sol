// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FixedPoint96} from "./FixedPoint96.sol";
import {Math} from "./Math.sol";
import {SafeCast} from "./SafeCast.sol";

/// @title SqrtPriceMath
/// @dev Implementation from https://github.com/Uniswap/v3-core/blob/0.8/contracts/libraries/SqrtPriceMath.sol

library SqrtPriceMath {
	using SafeCast for uint256;

	function getNextSqrtPriceFromAmount0RoundingUp(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amount,
		bool add
	) internal pure returns (uint160) {
		if (amount == 0) return sqrtPX96;
		uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

		if (add) {
			unchecked {
				uint256 product;
				if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
					uint256 denominator = numerator1 + product;
					if (denominator >= numerator1)
						return uint160(Math.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
				}
			}

			return uint160(Math.divRoundingUp(numerator1, (numerator1 / sqrtPX96) + amount));
		} else {
			unchecked {
				uint256 product;
				require((product = amount * sqrtPX96) / amount == sqrtPX96 || numerator1 > product);

				uint256 denominator = numerator1 - product;
				return Math.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
			}
		}
	}

	function getNextSqrtPriceFromAmount1RoundingDown(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amount,
		bool add
	) internal pure returns (uint160) {
		if (add) {
			uint256 quotient = (
				amount <= type(uint160).max
					? (amount << FixedPoint96.RESOLUTION) / liquidity
					: Math.mulDiv(amount, FixedPoint96.Q96, liquidity)
			);

			return (uint256(sqrtPX96) + quotient).toUint160();
		} else {
			uint256 quotient = (
				amount <= type(uint160).max
					? Math.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
					: Math.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
			);

			require(sqrtPX96 > quotient);

			unchecked {
				return uint160(sqrtPX96 - quotient);
			}
		}
	}

	function getNextSqrtPriceFromInput(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amountIn,
		bool zeroForOne
	) internal pure returns (uint160 sqrtQX96) {
		require(sqrtPX96 > 0);
		require(liquidity > 0);

		return
			zeroForOne
				? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
				: getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
	}

	function getNextSqrtPriceFromOutput(
		uint160 sqrtPX96,
		uint128 liquidity,
		uint256 amountOut,
		bool zeroForOne
	) internal pure returns (uint160 sqrtQX96) {
		require(sqrtPX96 > 0);
		require(liquidity > 0);

		return
			zeroForOne
				? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
				: getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
	}

	function getAmount0Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity,
		bool roundUp
	) internal pure returns (uint256 amount0) {
		unchecked {
			if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

			uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
			uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

			require(sqrtRatioAX96 > 0);

			return
				roundUp
					? Math.divRoundingUp(Math.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96), sqrtRatioAX96)
					: Math.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
		}
	}

	function getAmount1Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity,
		bool roundUp
	) internal pure returns (uint256 amount1) {
		unchecked {
			if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

			return
				roundUp
					? Math.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
					: Math.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
		}
	}

	function getAmount0Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		int128 liquidity
	) internal pure returns (int256 amount0) {
		unchecked {
			return
				liquidity < 0
					? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
					: getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
		}
	}

	function getAmount1Delta(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		int128 liquidity
	) internal pure returns (int256 amount1) {
		unchecked {
			return
				liquidity < 0
					? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
					: getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
		}
	}
}
