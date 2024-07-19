// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {IUniswapV3Factory, UniswapV3FactoryParameters, UniswapV3FactoryConstructor, UniswapV3FactoryTransient} from "src/uniswap/v3/UniswapV3Factory.sol";
import {IUniswapV3Pool, UniswapV3PoolParameters, UniswapV3PoolConstructor, UniswapV3PoolTransient} from "src/uniswap/v3/UniswapV3Pool.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {Tick} from "src/libraries/Tick.sol";
import {Currency} from "src/types/Currency.sol";
import {Common} from "./shared/Common.sol";

contract UniswapV3FactoryTest is Test, Common {
	using PoolAddress for address;

	IUniswapV3Factory v3Factory;
	UniswapV3FactoryParameters pfactory;
	UniswapV3FactoryConstructor cfactory;
	UniswapV3FactoryTransient tfactory;

	MockERC20 mock0;
	MockERC20 mock1;

	Currency currency0;
	Currency currency1;
	uint24 fee;
	int24 tickSpacing;
	uint128 maxLiquidityPerTick;

	function setUp() public {
		fork(true);

		v3Factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
		pfactory = new UniswapV3FactoryParameters();
		cfactory = new UniswapV3FactoryConstructor();
		tfactory = new UniswapV3FactoryTransient();

		mock0 = deployMockERC20("Mock Currency", "MCR", 18);
		mock1 = deployMockERC20("Mock Token", "MTK", 18);

		currency0 = Currency.wrap(address(mock0));
		currency1 = Currency.wrap(address(mock1));
		if (currency0 > currency1) (currency0, currency1) = (currency1, currency0);

		fee = FEE_MEDIUM;
		tickSpacing = v3Factory.feeAmountTickSpacing(fee);
		maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(tickSpacing);
	}

	function test_createPool() public {
		_testCreatePool(address(v3Factory));
	}

	function test_createPoolWithParameters() public {
		_testCreatePool(address(pfactory));
	}

	function test_createPoolWithConstructor() public {
		_testCreatePool(address(cfactory));
	}

	function test_createPoolWithTransient() public {
		_testCreatePool(address(tfactory));
	}

	function _testCreatePool(address factory) internal returns (address pool, uint256 gasUsed) {
		bytes32 initCodeHash;

		if (factory == UNISWAP_V3_FACTORY) {
			initCodeHash = UNISWAP_V3_POOL_INIT_CODE_HASH;
		} else if (factory == address(pfactory)) {
			initCodeHash = keccak256(abi.encodePacked(type(UniswapV3PoolParameters).creationCode));
		} else if (factory == address(tfactory)) {
			initCodeHash = keccak256(abi.encodePacked(type(UniswapV3PoolTransient).creationCode));
		} else {
			bytes memory encodedParams = abi.encode(currency0, currency1, fee, tickSpacing);
			initCodeHash = keccak256(abi.encodePacked(type(UniswapV3PoolConstructor).creationCode, encodedParams));
		}

		gasUsed = gasleft();
		pool = IUniswapV3Factory(factory).createPool(currency0, currency1, fee);
		gasUsed -= gasleft();

		assertEq(PoolAddress.compute(factory, initCodeHash, currency0, currency1, fee), pool, "!computePool");
		assertEq(IUniswapV3Factory(factory).getPool(currency0, currency1, fee), pool, "!getPool");
		assertEq(IUniswapV3Pool(pool).factory(), factory, "!factory");
		assertEq(IUniswapV3Pool(pool).token0(), currency0, "!token0");
		assertEq(IUniswapV3Pool(pool).token1(), currency1, "!token1");
		assertEq(IUniswapV3Pool(pool).fee(), fee, "!fee");
		assertEq(IUniswapV3Pool(pool).tickSpacing(), tickSpacing, "!tickSpacing");
		assertEq(IUniswapV3Pool(pool).maxLiquidityPerTick(), maxLiquidityPerTick, "!maxLiquidityPerTick");
	}
}
