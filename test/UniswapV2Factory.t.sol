// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {IUniswapV2Factory, UniswapV2FactoryInitializer, UniswapV2FactoryConstructor, UniswapV2FactoryTransient} from "src/uniswap/v2/UniswapV2Factory.sol";
import {IUniswapV2Pair, UniswapV2PairInitializer, UniswapV2PairConstructor, UniswapV2PairTransient} from "src/uniswap/v2/UniswapV2Pair.sol";
import {PoolAddress} from "src/libraries/PoolAddress.sol";
import {Currency} from "src/types/Currency.sol";
import {Common} from "./shared/Common.sol";

contract UniswapV2FactoryTest is Test, Common {
	IUniswapV2Factory v2Factory;
	UniswapV2FactoryInitializer ifactory;
	UniswapV2FactoryConstructor cfactory;
	UniswapV2FactoryTransient tfactory;

	MockERC20 mock0;
	MockERC20 mock1;

	Currency currency0;
	Currency currency1;

	function setUp() public {
		fork(true);

		v2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
		ifactory = new UniswapV2FactoryInitializer(v2Factory.feeToSetter());
		cfactory = new UniswapV2FactoryConstructor(v2Factory.feeToSetter());
		tfactory = new UniswapV2FactoryTransient(v2Factory.feeToSetter());

		mock0 = deployMockERC20("Mock Currency", "MCR", 18);
		mock1 = deployMockERC20("Mock Token", "MTK", 18);

		currency0 = Currency.wrap(address(mock0));
		currency1 = Currency.wrap(address(mock1));
		if (currency0 > currency1) (currency0, currency1) = (currency1, currency0);
	}

	function test_createPair() public {
		_testCreatePair(address(v2Factory));
	}

	function test_createPairWithInitializer() public {
		_testCreatePair(address(ifactory));
	}

	function test_createPairWithConstructor() public {
		_testCreatePair(address(cfactory));
	}

	function test_createPairWithTransient() public {
		_testCreatePair(address(tfactory));
	}

	function _testCreatePair(address factory) internal returns (address pair, uint256 gasUsed) {
		bytes32 initCodeHash;

		if (factory == UNISWAP_V2_FACTORY) {
			initCodeHash = UNISWAP_V2_PAIR_INIT_CODE_HASH;
		} else if (factory == address(ifactory)) {
			initCodeHash = keccak256(abi.encodePacked(type(UniswapV2PairInitializer).creationCode));
		} else if (factory == address(tfactory)) {
			initCodeHash = keccak256(abi.encodePacked(type(UniswapV2PairTransient).creationCode));
		} else {
			bytes memory encodedParams = abi.encode(currency0, currency1);
			initCodeHash = keccak256(abi.encodePacked(type(UniswapV2PairConstructor).creationCode, encodedParams));
		}

		gasUsed = gasleft();
		pair = IUniswapV2Factory(factory).createPair(currency0, currency1);
		gasUsed -= gasleft();

		assertEq(PoolAddress.compute(factory, initCodeHash, currency0, currency1), pair, "!computePair");
		assertEq(IUniswapV2Factory(factory).getPair(currency0, currency1), pair, "!getPair");
		assertEq(IUniswapV2Pair(pair).factory(), factory, "!factory");
		assertEq(IUniswapV2Pair(pair).token0(), currency0, "!token0");
		assertEq(IUniswapV2Pair(pair).token1(), currency1, "!token1");
	}
}
