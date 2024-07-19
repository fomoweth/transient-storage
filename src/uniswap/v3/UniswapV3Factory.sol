// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV3Factory} from "src/interfaces/v3/IUniswapV3Factory.sol";
import {IUniswapV3PoolDeployer} from "src/interfaces/v3/IUniswapV3PoolDeployer.sol";
import {Currency} from "src/types/Currency.sol";
import {NoDelegateCall} from "./NoDelegateCall.sol";
import {UniswapV3PoolParameters, UniswapV3PoolConstructor, UniswapV3PoolTransient} from "./UniswapV3Pool.sol";

abstract contract UniswapV3Factory is IUniswapV3Factory, NoDelegateCall {
	address private _owner;

	mapping(uint24 fee => int24 tickSpacing) private _feeAmountTickSpacing;
	mapping(Currency currencyA => mapping(Currency currencyB => mapping(uint24 fee => address pool))) private _pools;

	constructor() {
		_owner = msg.sender;
		emit OwnerChanged(address(0), msg.sender);

		_enableFeeAmount(100, 1);
		_enableFeeAmount(500, 10);
		_enableFeeAmount(3000, 60);
		_enableFeeAmount(10000, 200);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	function feeAmountTickSpacing(uint24 fee) public view returns (int24) {
		return _feeAmountTickSpacing[fee];
	}

	function getPool(Currency currencyA, Currency currencyB, uint24 fee) public view returns (address pool) {
		return _pools[currencyA][currencyB][fee];
	}

	function createPool(
		Currency currencyA,
		Currency currencyB,
		uint24 fee
	) external noDelegateCall returns (address pool) {
		require(currencyA != currencyB);

		(Currency currency0, Currency currency1) = currencyA < currencyB
			? (currencyA, currencyB)
			: (currencyB, currencyA);

		require(!currency0.isZero());

		int24 tickSpacing = feeAmountTickSpacing(fee);

		require(tickSpacing != 0);
		require(getPool(currency0, currency1, fee) == address(0));

		pool = deploy(currency0, currency1, fee, tickSpacing);

		_pools[currency0][currency1][fee] = pool;
		_pools[currency1][currency0][fee] = pool;

		emit PoolCreated(currency0, currency1, fee, tickSpacing, pool);
	}

	function deploy(
		Currency currency0,
		Currency currency1,
		uint24 fee,
		int24 tickSpacing
	) internal virtual returns (address pool);

	function setOwner(address account) external {
		require(msg.sender == owner());
		emit OwnerChanged(owner(), account);
		_owner = account;
	}

	function enableFeeAmount(uint24 fee, int24 tickSpacing) public {
		require(msg.sender == owner());
		require(fee < 1000000);
		require(tickSpacing > 0 && tickSpacing < 16384);
		require(feeAmountTickSpacing(fee) == 0);

		_enableFeeAmount(fee, tickSpacing);
	}

	function _enableFeeAmount(uint24 fee, int24 tickSpacing) private {
		_feeAmountTickSpacing[fee] = tickSpacing;
		emit FeeAmountEnabled(fee, tickSpacing);
	}
}

contract UniswapV3FactoryParameters is IUniswapV3PoolDeployer, UniswapV3Factory {
	struct Parameters {
		Currency currency0;
		Currency currency1;
		uint24 fee;
		int24 tickSpacing;
	}

	Parameters public parameters;

	function deploy(
		Currency currency0,
		Currency currency1,
		uint24 fee,
		int24 tickSpacing
	) internal virtual override returns (address pool) {
		parameters = Parameters({currency0: currency0, currency1: currency1, fee: fee, tickSpacing: tickSpacing});

		pool = address(new UniswapV3PoolParameters{salt: keccak256(abi.encode(currency0, currency1, fee))}());

		delete parameters;
	}
}

contract UniswapV3FactoryConstructor is UniswapV3Factory {
	function deploy(
		Currency currency0,
		Currency currency1,
		uint24 fee,
		int24 tickSpacing
	) internal virtual override returns (address pool) {
		bytes memory bytecode = abi.encodePacked(
			type(UniswapV3PoolConstructor).creationCode,
			abi.encode(currency0, currency1, fee, tickSpacing)
		);

		bytes32 salt = keccak256(abi.encode(currency0, currency1, fee));

		assembly ("memory-safe") {
			pool := create2(0x00, add(bytecode, 0x20), mload(bytecode), salt)

			if iszero(pool) {
				mstore(0x00, 0xdc802c74) // PoolCreationFailed()
				revert(0x1c, 0x04)
			}
		}
	}
}

contract UniswapV3FactoryTransient is IUniswapV3PoolDeployer, UniswapV3Factory {
	// bytes32(uint256(keccak256("UniswapV3Factory.poolContext.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant POOL_CONTEXT_SLOT = 0x4cbc4600075b2f8c615834a56221934e92a9a18daaa9939c06932f192e907900;

	function deploy(
		Currency currency0,
		Currency currency1,
		uint24 fee,
		int24 tickSpacing
	) internal virtual override returns (address pool) {
		bytes memory bytecode = type(UniswapV3PoolTransient).creationCode;

		bytes32 salt = keccak256(abi.encode(currency0, currency1, fee));

		assembly ("memory-safe") {
			if iszero(iszero(tload(POOL_CONTEXT_SLOT))) {
				mstore(0x00, 0x55b9fb08) // SlotNotEmpty()
				revert(0x1c, 0x04)
			}

			tstore(POOL_CONTEXT_SLOT, currency0)
			tstore(add(POOL_CONTEXT_SLOT, 0x01), currency1)
			tstore(add(POOL_CONTEXT_SLOT, 0x02), fee)
			tstore(add(POOL_CONTEXT_SLOT, 0x03), tickSpacing)

			pool := create2(0x00, add(bytecode, 0x20), mload(bytecode), salt)

			if iszero(pool) {
				mstore(0x00, 0xdc802c74) // PoolCreationFailed()
				revert(0x1c, 0x04)
			}

			tstore(POOL_CONTEXT_SLOT, 0x00)
			tstore(add(POOL_CONTEXT_SLOT, 0x01), 0x00)
			tstore(add(POOL_CONTEXT_SLOT, 0x02), 0x00)
			tstore(add(POOL_CONTEXT_SLOT, 0x03), 0x00)
		}
	}

	function parameters()
		external
		view
		returns (Currency currency0, Currency currency1, uint24 fee, int24 tickSpacing)
	{
		assembly ("memory-safe") {
			if iszero(tload(POOL_CONTEXT_SLOT)) {
				mstore(0x00, 0xce174065) // SlotEmpty()
				revert(0x1c, 0x04)
			}

			currency0 := tload(POOL_CONTEXT_SLOT)
			currency1 := tload(add(POOL_CONTEXT_SLOT, 0x01))
			fee := tload(add(POOL_CONTEXT_SLOT, 0x02))
			tickSpacing := tload(add(POOL_CONTEXT_SLOT, 0x03))
		}
	}
}
