// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV3Pool} from "src/interfaces/v3/IUniswapV3Pool.sol";
import {IUniswapV3PoolDeployer} from "src/interfaces/v3/IUniswapV3PoolDeployer.sol";
import {IUniswapV3Factory} from "src/interfaces/v3/IUniswapV3Factory.sol";
import {IUniswapV3FlashCallback, IUniswapV3MintCallback, IUniswapV3SwapCallback} from "src/interfaces/v3/IUniswapV3Callbacks.sol";
import {FixedPoint128} from "src/libraries/FixedPoint128.sol";
import {LiquidityMath} from "src/libraries/LiquidityMath.sol";
import {Math} from "src/libraries/Math.sol";
import {Oracle} from "src/libraries/Oracle.sol";
import {Position} from "src/libraries/Position.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {SqrtPriceMath} from "src/libraries/SqrtPriceMath.sol";
import {SwapMath} from "src/libraries/SwapMath.sol";
import {Tick} from "src/libraries/Tick.sol";
import {TickBitmap} from "src/libraries/TickBitmap.sol";
import {TickMath} from "src/libraries/TickMath.sol";
import {Currency} from "src/types/Currency.sol";
import {NoDelegateCall} from "./NoDelegateCall.sol";

/// @title UniswapV3Pool
/// @dev Implementation from https://github.com/Uniswap/v3-core/blob/0.8/contracts/UniswapV3Pool.sol

abstract contract UniswapV3Pool is IUniswapV3Pool, NoDelegateCall {
	using SafeCast for uint256;
	using Tick for mapping(int24 => Tick.Info);
	using TickBitmap for mapping(int16 => uint256);
	using Position for mapping(bytes32 => Position.Info);
	using Position for Position.Info;
	using Oracle for Oracle.Observation[65535];

	error LOK();
	error TLU();
	error TLM();
	error TUM();
	error AI();
	error M0();
	error M1();
	error AS();
	error IIA();
	error F0();
	error F1();

	address public immutable factory;

	Currency public immutable token0;

	Currency public immutable token1;

	uint24 public immutable fee;

	int24 public immutable tickSpacing;

	uint128 public immutable maxLiquidityPerTick;

	struct Slot0 {
		uint160 sqrtPriceX96;
		int24 tick;
		uint16 observationIndex;
		uint16 observationCardinality;
		uint16 observationCardinalityNext;
		uint8 feeProtocol;
		bool unlocked;
	}

	Slot0 public slot0;

	uint256 public feeGrowthGlobal0X128;

	uint256 public feeGrowthGlobal1X128;

	struct ProtocolFees {
		uint128 token0;
		uint128 token1;
	}

	ProtocolFees public protocolFees;

	uint128 public liquidity;

	mapping(int24 tick => Tick.Info info) public ticks;

	mapping(int16 wordPos => uint256 bitmap) public tickBitmap;

	mapping(bytes32 key => Position.Info info) public positions;

	Oracle.Observation[65535] public observations;

	modifier lock() {
		if (!slot0.unlocked) revert LOK();
		slot0.unlocked = false;
		_;
		slot0.unlocked = true;
	}

	modifier onlyFactoryOwner() {
		require(msg.sender == IUniswapV3Factory(factory).owner());
		_;
	}

	constructor() {
		factory = msg.sender;
	}

	function checkTicks(int24 tickLower, int24 tickUpper) private pure {
		if (tickLower >= tickUpper) revert TLU();
		if (tickLower < TickMath.MIN_TICK) revert TLM();
		if (tickUpper > TickMath.MAX_TICK) revert TUM();
	}

	function _blockTimestamp() internal view virtual returns (uint32) {
		return block.timestamp.toUint32();
	}

	function balance0() private view returns (uint256) {
		return token0.balanceOfSelf();
	}

	function balance1() private view returns (uint256) {
		return token1.balanceOfSelf();
	}

	function transfer0(address recipient, uint256 value) private {
		token0.transfer(recipient, value);
	}

	function transfer1(address recipient, uint256 value) private {
		token1.transfer(recipient, value);
	}

	function snapshotCumulativesInside(
		int24 tickLower,
		int24 tickUpper
	)
		external
		view
		noDelegateCall
		returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside)
	{
		checkTicks(tickLower, tickUpper);

		int56 tickCumulativeLower;
		int56 tickCumulativeUpper;
		uint160 secondsPerLiquidityOutsideLowerX128;
		uint160 secondsPerLiquidityOutsideUpperX128;
		uint32 secondsOutsideLower;
		uint32 secondsOutsideUpper;

		{
			Tick.Info storage lower = ticks[tickLower];
			Tick.Info storage upper = ticks[tickUpper];

			bool initializedLower;
			(tickCumulativeLower, secondsPerLiquidityOutsideLowerX128, secondsOutsideLower, initializedLower) = (
				lower.tickCumulativeOutside,
				lower.secondsPerLiquidityOutsideX128,
				lower.secondsOutside,
				lower.initialized
			);
			require(initializedLower);

			bool initializedUpper;
			(tickCumulativeUpper, secondsPerLiquidityOutsideUpperX128, secondsOutsideUpper, initializedUpper) = (
				upper.tickCumulativeOutside,
				upper.secondsPerLiquidityOutsideX128,
				upper.secondsOutside,
				upper.initialized
			);
			require(initializedUpper);
		}

		Slot0 memory _slot0 = slot0;

		unchecked {
			if (_slot0.tick < tickLower) {
				return (
					tickCumulativeLower - tickCumulativeUpper,
					secondsPerLiquidityOutsideLowerX128 - secondsPerLiquidityOutsideUpperX128,
					secondsOutsideLower - secondsOutsideUpper
				);
			} else if (_slot0.tick < tickUpper) {
				uint32 time = _blockTimestamp();

				(int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) = observations.observeSingle(
					time,
					0,
					_slot0.tick,
					_slot0.observationIndex,
					liquidity,
					_slot0.observationCardinality
				);

				return (
					tickCumulative - tickCumulativeLower - tickCumulativeUpper,
					secondsPerLiquidityCumulativeX128 -
						secondsPerLiquidityOutsideLowerX128 -
						secondsPerLiquidityOutsideUpperX128,
					time - secondsOutsideLower - secondsOutsideUpper
				);
			} else {
				return (
					tickCumulativeUpper - tickCumulativeLower,
					secondsPerLiquidityOutsideUpperX128 - secondsPerLiquidityOutsideLowerX128,
					secondsOutsideUpper - secondsOutsideLower
				);
			}
		}
	}

	function observe(
		uint32[] calldata secondsAgos
	)
		external
		view
		noDelegateCall
		returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)
	{
		return
			observations.observe(
				_blockTimestamp(),
				secondsAgos,
				slot0.tick,
				slot0.observationIndex,
				liquidity,
				slot0.observationCardinality
			);
	}

	function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external lock noDelegateCall {
		uint16 observationCardinalityNextOld = slot0.observationCardinalityNext;
		uint16 observationCardinalityNextNew = observations.grow(
			observationCardinalityNextOld,
			observationCardinalityNext
		);
		slot0.observationCardinalityNext = observationCardinalityNextNew;

		if (observationCardinalityNextOld != observationCardinalityNextNew)
			emit IncreaseObservationCardinalityNext(observationCardinalityNextOld, observationCardinalityNextNew);
	}

	function initialize(uint160 sqrtPriceX96) external {
		if (slot0.sqrtPriceX96 != 0) revert AI();

		int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

		(uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

		slot0 = Slot0({
			sqrtPriceX96: sqrtPriceX96,
			tick: tick,
			observationIndex: 0,
			observationCardinality: cardinality,
			observationCardinalityNext: cardinalityNext,
			feeProtocol: 0,
			unlocked: true
		});

		emit Initialize(sqrtPriceX96, tick);
	}

	struct ModifyPositionParams {
		address owner;
		int24 tickLower;
		int24 tickUpper;
		int128 liquidityDelta;
	}

	function _modifyPosition(
		ModifyPositionParams memory params
	) private noDelegateCall returns (Position.Info storage position, int256 amount0, int256 amount1) {
		checkTicks(params.tickLower, params.tickUpper);

		Slot0 memory _slot0 = slot0;

		position = _updatePosition(
			params.owner,
			params.tickLower,
			params.tickUpper,
			params.liquidityDelta,
			_slot0.tick
		);

		if (params.liquidityDelta != 0) {
			if (_slot0.tick < params.tickLower) {
				amount0 = SqrtPriceMath.getAmount0Delta(
					TickMath.getSqrtRatioAtTick(params.tickLower),
					TickMath.getSqrtRatioAtTick(params.tickUpper),
					params.liquidityDelta
				);
			} else if (_slot0.tick < params.tickUpper) {
				uint128 liquidityBefore = liquidity;

				(slot0.observationIndex, slot0.observationCardinality) = observations.write(
					_slot0.observationIndex,
					_blockTimestamp(),
					_slot0.tick,
					liquidityBefore,
					_slot0.observationCardinality,
					_slot0.observationCardinalityNext
				);

				amount0 = SqrtPriceMath.getAmount0Delta(
					_slot0.sqrtPriceX96,
					TickMath.getSqrtRatioAtTick(params.tickUpper),
					params.liquidityDelta
				);

				amount1 = SqrtPriceMath.getAmount1Delta(
					TickMath.getSqrtRatioAtTick(params.tickLower),
					_slot0.sqrtPriceX96,
					params.liquidityDelta
				);

				liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
			} else {
				amount1 = SqrtPriceMath.getAmount1Delta(
					TickMath.getSqrtRatioAtTick(params.tickLower),
					TickMath.getSqrtRatioAtTick(params.tickUpper),
					params.liquidityDelta
				);
			}
		}
	}

	function _updatePosition(
		address owner,
		int24 tickLower,
		int24 tickUpper,
		int128 liquidityDelta,
		int24 tick
	) private returns (Position.Info storage position) {
		position = positions.get(owner, tickLower, tickUpper);

		uint256 _feeGrowthGlobal0X128 = feeGrowthGlobal0X128;
		uint256 _feeGrowthGlobal1X128 = feeGrowthGlobal1X128;

		bool flippedLower;
		bool flippedUpper;

		if (liquidityDelta != 0) {
			uint32 time = _blockTimestamp();

			(int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) = observations.observeSingle(
				time,
				0,
				slot0.tick,
				slot0.observationIndex,
				liquidity,
				slot0.observationCardinality
			);

			flippedLower = ticks.update(
				tickLower,
				tick,
				liquidityDelta,
				_feeGrowthGlobal0X128,
				_feeGrowthGlobal1X128,
				secondsPerLiquidityCumulativeX128,
				tickCumulative,
				time,
				false,
				maxLiquidityPerTick
			);

			flippedUpper = ticks.update(
				tickUpper,
				tick,
				liquidityDelta,
				_feeGrowthGlobal0X128,
				_feeGrowthGlobal1X128,
				secondsPerLiquidityCumulativeX128,
				tickCumulative,
				time,
				true,
				maxLiquidityPerTick
			);

			if (flippedLower) {
				tickBitmap.flipTick(tickLower, tickSpacing);
			}
			if (flippedUpper) {
				tickBitmap.flipTick(tickUpper, tickSpacing);
			}
		}

		(uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks.getFeeGrowthInside(
			tickLower,
			tickUpper,
			tick,
			_feeGrowthGlobal0X128,
			_feeGrowthGlobal1X128
		);

		position.update(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

		if (liquidityDelta < 0) {
			if (flippedLower) {
				ticks.clear(tickLower);
			}
			if (flippedUpper) {
				ticks.clear(tickUpper);
			}
		}
	}

	function mint(
		address recipient,
		int24 tickLower,
		int24 tickUpper,
		uint128 amount,
		bytes calldata data
	) external lock returns (uint256 amount0, uint256 amount1) {
		require(amount > 0);

		(, int256 amount0Int, int256 amount1Int) = _modifyPosition(
			ModifyPositionParams({
				owner: recipient,
				tickLower: tickLower,
				tickUpper: tickUpper,
				liquidityDelta: uint256(amount).toInt128()
			})
		);

		amount0 = uint256(amount0Int);
		amount1 = uint256(amount1Int);

		uint256 balance0Before;
		uint256 balance1Before;

		if (amount0 > 0) balance0Before = balance0();
		if (amount1 > 0) balance1Before = balance1();

		IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);

		if (amount0 > 0 && balance0Before + amount0 > balance0()) revert M0();
		if (amount1 > 0 && balance1Before + amount1 > balance1()) revert M1();

		emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
	}

	function collect(
		address recipient,
		int24 tickLower,
		int24 tickUpper,
		uint128 amount0Requested,
		uint128 amount1Requested
	) external lock returns (uint128 amount0, uint128 amount1) {
		Position.Info storage position = positions.get(msg.sender, tickLower, tickUpper);

		amount0 = amount0Requested > position.tokensOwed0 ? position.tokensOwed0 : amount0Requested;
		amount1 = amount1Requested > position.tokensOwed1 ? position.tokensOwed1 : amount1Requested;

		unchecked {
			if (amount0 > 0) {
				position.tokensOwed0 -= amount0;
				transfer0(recipient, amount0);
			}

			if (amount1 > 0) {
				position.tokensOwed1 -= amount1;
				transfer1(recipient, amount1);
			}
		}

		emit Collect(msg.sender, recipient, tickLower, tickUpper, amount0, amount1);
	}

	function burn(
		int24 tickLower,
		int24 tickUpper,
		uint128 amount
	) external lock returns (uint256 amount0, uint256 amount1) {
		unchecked {
			(Position.Info storage position, int256 amount0Int, int256 amount1Int) = _modifyPosition(
				ModifyPositionParams({
					owner: msg.sender,
					tickLower: tickLower,
					tickUpper: tickUpper,
					liquidityDelta: -uint256(amount).toInt128()
				})
			);

			amount0 = uint256(-amount0Int);
			amount1 = uint256(-amount1Int);

			if (amount0 > 0 || amount1 > 0) {
				(position.tokensOwed0, position.tokensOwed1) = (
					position.tokensOwed0 + uint128(amount0),
					position.tokensOwed1 + uint128(amount1)
				);
			}

			emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
		}
	}

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
		uint256 feeGrowthGlobalX128;
		uint128 protocolFee;
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

	function swap(
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bytes calldata data
	) external noDelegateCall returns (int256 amount0, int256 amount1) {
		if (amountSpecified == 0) revert AS();

		Slot0 memory slot0Start = slot0;
		if (!slot0Start.unlocked) revert LOK();

		require(
			zeroForOne
				? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
				: sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO
		);

		slot0.unlocked = false;

		SwapCache memory cache = SwapCache({
			liquidityStart: liquidity,
			blockTimestamp: _blockTimestamp(),
			feeProtocol: zeroForOne ? (slot0Start.feeProtocol % 16) : (slot0Start.feeProtocol >> 4),
			secondsPerLiquidityCumulativeX128: 0,
			tickCumulative: 0,
			computedLatestObservation: false
		});

		bool exactInput = amountSpecified > 0;

		SwapState memory state = SwapState({
			amountSpecifiedRemaining: amountSpecified,
			amountCalculated: 0,
			sqrtPriceX96: slot0Start.sqrtPriceX96,
			tick: slot0Start.tick,
			feeGrowthGlobalX128: zeroForOne ? feeGrowthGlobal0X128 : feeGrowthGlobal1X128,
			protocolFee: 0,
			liquidity: cache.liquidityStart
		});

		while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
			StepComputations memory step;

			step.sqrtPriceStartX96 = state.sqrtPriceX96;

			(step.tickNext, step.initialized) = tickBitmap.nextInitializedTickWithinOneWord(
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
				fee
			);

			if (exactInput) {
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

			if (cache.feeProtocol > 0) {
				unchecked {
					uint256 delta = step.feeAmount / cache.feeProtocol;
					step.feeAmount -= delta;
					state.protocolFee += uint128(delta);
				}
			}

			if (state.liquidity > 0) {
				unchecked {
					state.feeGrowthGlobalX128 += Math.mulDiv(step.feeAmount, FixedPoint128.Q128, state.liquidity);
				}
			}

			if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
				if (step.initialized) {
					if (!cache.computedLatestObservation) {
						(cache.tickCumulative, cache.secondsPerLiquidityCumulativeX128) = observations.observeSingle(
							cache.blockTimestamp,
							0,
							slot0Start.tick,
							slot0Start.observationIndex,
							cache.liquidityStart,
							slot0Start.observationCardinality
						);

						cache.computedLatestObservation = true;
					}

					int128 liquidityNet = ticks.cross(
						step.tickNext,
						(zeroForOne ? state.feeGrowthGlobalX128 : feeGrowthGlobal0X128),
						(zeroForOne ? feeGrowthGlobal1X128 : state.feeGrowthGlobalX128),
						cache.secondsPerLiquidityCumulativeX128,
						cache.tickCumulative,
						cache.blockTimestamp
					);

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

		if (state.tick != slot0Start.tick) {
			(uint16 observationIndex, uint16 observationCardinality) = observations.write(
				slot0Start.observationIndex,
				cache.blockTimestamp,
				slot0Start.tick,
				cache.liquidityStart,
				slot0Start.observationCardinality,
				slot0Start.observationCardinalityNext
			);

			(slot0.sqrtPriceX96, slot0.tick, slot0.observationIndex, slot0.observationCardinality) = (
				state.sqrtPriceX96,
				state.tick,
				observationIndex,
				observationCardinality
			);
		} else {
			slot0.sqrtPriceX96 = state.sqrtPriceX96;
		}

		if (cache.liquidityStart != state.liquidity) liquidity = state.liquidity;

		if (zeroForOne) {
			feeGrowthGlobal0X128 = state.feeGrowthGlobalX128;

			unchecked {
				if (state.protocolFee > 0) protocolFees.token0 += state.protocolFee;
			}
		} else {
			feeGrowthGlobal1X128 = state.feeGrowthGlobalX128;

			unchecked {
				if (state.protocolFee > 0) protocolFees.token1 += state.protocolFee;
			}
		}

		unchecked {
			(amount0, amount1) = zeroForOne == exactInput
				? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
				: (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
		}

		if (zeroForOne) {
			unchecked {
				if (amount1 < 0) transfer1(recipient, uint256(-amount1));
			}

			uint256 balance0Before = balance0();

			IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);

			if (balance0Before + uint256(amount0) > balance0()) revert IIA();
		} else {
			unchecked {
				if (amount0 < 0) transfer0(recipient, uint256(-amount0));
			}

			uint256 balance1Before = balance1();

			IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);

			if (balance1Before + uint256(amount1) > balance1()) revert IIA();
		}

		emit Swap(msg.sender, recipient, amount0, amount1, state.sqrtPriceX96, state.liquidity, state.tick);
		slot0.unlocked = true;
	}

	function flash(
		address recipient,
		uint256 amount0,
		uint256 amount1,
		bytes calldata data
	) external lock noDelegateCall {
		uint128 _liquidity = liquidity;
		require(_liquidity > 0);

		uint256 fee0 = Math.mulDivRoundingUp(amount0, fee, 1e6);
		uint256 fee1 = Math.mulDivRoundingUp(amount1, fee, 1e6);

		uint256 balance0Before = balance0();
		uint256 balance1Before = balance1();

		if (amount0 > 0) transfer0(recipient, amount0);
		if (amount1 > 0) transfer1(recipient, amount1);

		IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(fee0, fee1, data);

		uint256 balance0After = balance0();
		uint256 balance1After = balance1();

		if (balance0Before + fee0 > balance0After) revert F0();
		if (balance1Before + fee1 > balance1After) revert F1();

		unchecked {
			uint256 paid0 = balance0After - balance0Before;
			uint256 paid1 = balance1After - balance1Before;

			if (paid0 > 0) {
				uint8 feeProtocol0 = slot0.feeProtocol % 16;
				uint256 pFees0 = feeProtocol0 == 0 ? 0 : paid0 / feeProtocol0;
				if (uint128(pFees0) > 0) protocolFees.token0 += uint128(pFees0);

				feeGrowthGlobal0X128 += Math.mulDiv(paid0 - pFees0, FixedPoint128.Q128, _liquidity);
			}

			if (paid1 > 0) {
				uint8 feeProtocol1 = slot0.feeProtocol >> 4;
				uint256 pFees1 = feeProtocol1 == 0 ? 0 : paid1 / feeProtocol1;
				if (uint128(pFees1) > 0) protocolFees.token1 += uint128(pFees1);

				feeGrowthGlobal1X128 += Math.mulDiv(paid1 - pFees1, FixedPoint128.Q128, _liquidity);
			}

			emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
		}
	}

	function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external lock onlyFactoryOwner {
		unchecked {
			require(
				(feeProtocol0 == 0 || (feeProtocol0 >= 4 && feeProtocol0 <= 10)) &&
					(feeProtocol1 == 0 || (feeProtocol1 >= 4 && feeProtocol1 <= 10))
			);

			uint8 feeProtocolOld = slot0.feeProtocol;
			slot0.feeProtocol = feeProtocol0 + (feeProtocol1 << 4);

			emit SetFeeProtocol(feeProtocolOld % 16, feeProtocolOld >> 4, feeProtocol0, feeProtocol1);
		}
	}

	function collectProtocol(
		address recipient,
		uint128 amount0Requested,
		uint128 amount1Requested
	) external lock onlyFactoryOwner returns (uint128 amount0, uint128 amount1) {
		amount0 = amount0Requested > protocolFees.token0 ? protocolFees.token0 : amount0Requested;
		amount1 = amount1Requested > protocolFees.token1 ? protocolFees.token1 : amount1Requested;

		unchecked {
			if (amount0 > 0) {
				if (amount0 == protocolFees.token0) --amount0;
				protocolFees.token0 -= amount0;
				transfer0(recipient, amount0);
			}

			if (amount1 > 0) {
				if (amount1 == protocolFees.token1) --amount1;
				protocolFees.token1 -= amount1;
				transfer1(recipient, amount1);
			}
		}

		emit CollectProtocol(msg.sender, recipient, amount0, amount1);
	}
}

contract UniswapV3PoolParameters is UniswapV3Pool {
	constructor() {
		int24 ts;
		(token0, token1, fee, ts) = IUniswapV3PoolDeployer(msg.sender).parameters();
		tickSpacing = ts;
		maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(ts);
	}
}

contract UniswapV3PoolConstructor is UniswapV3Pool {
	constructor(Currency _token0, Currency _token1, uint24 _fee, int24 _tickSpacing) {
		token0 = _token0;
		token1 = _token1;
		fee = _fee;
		tickSpacing = _tickSpacing;
		maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
	}
}

contract UniswapV3PoolTransient is UniswapV3Pool {
	constructor() {
		int24 ts;
		(token0, token1, fee, ts) = IUniswapV3PoolDeployer(msg.sender).parameters();
		tickSpacing = ts;
		maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(ts);
	}
}
