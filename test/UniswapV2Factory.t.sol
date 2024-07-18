// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {UniswapV2Factory, CUniswapV2Factory, TUniswapV2Factory} from "src/uniswap/v2/UniswapV2Factory.sol";
import {IUniswapV2Factory} from "src/interfaces/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "src/interfaces/v2/IUniswapV2Pair.sol";
import {Currency} from "src/types/Currency.sol";
import {Common} from "./shared/Common.sol";

contract UniswapV2FactoryTest is Test, Common {
	IUniswapV2Factory ofactory;
	UniswapV2Factory ifactory;
	CUniswapV2Factory cfactory;
	TUniswapV2Factory tfactory;

	function setUp() public {
		fork(true);

		ofactory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
		ifactory = new UniswapV2Factory(ofactory.feeToSetter());
		cfactory = new CUniswapV2Factory(ofactory.feeToSetter());
		tfactory = new TUniswapV2Factory(ofactory.feeToSetter());
	}

	function test_createPairOriginal(uint256 i) public {
		_testCreatePair(address(ofactory), i);
	}

	function test_createPairWithInitialize(uint256 i) public {
		_testCreatePair(address(ifactory), i);
	}

	function test_createPairWithConstructor(uint256 i) public {
		_testCreatePair(address(cfactory), i);
	}

	function test_createPairWithTransient(uint256 i) public {
		_testCreatePair(address(tfactory), i);
	}

	function _testCreatePair(address factory, uint256 i) internal returns (address pair) {
		i = bound(i, 0, 1000);

		MockERC20 mock0 = deployMockERC20("Mock ERC20", "MERC", 18);
		MockERC20 mock1 = deployMockERC20("Mock Token", "MTK", 18);

		Currency currency0 = Currency.wrap(address(mock0));
		Currency currency1 = Currency.wrap(address(mock1));
		if (currency0 > currency1) (currency0, currency1) = (currency1, currency0);

		pair = IUniswapV2Factory(factory).createPair(currency0, currency1);

		assertEq(IUniswapV2Factory(factory).getPair(currency0, currency1), pair, "!getPair");
		assertEq(IUniswapV2Pair(pair).token0(), currency0, "!token0");
		assertEq(IUniswapV2Pair(pair).token1(), currency1, "!token1");
	}
}
