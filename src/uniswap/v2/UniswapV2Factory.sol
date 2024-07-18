// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV2Factory} from "src/interfaces/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "src/interfaces/v2/IUniswapV2Pair.sol";
import {Currency} from "src/types/Currency.sol";
import {UniswapV2Pair, CUniswapV2Pair, TUniswapV2Pair} from "./UniswapV2Pair.sol";

contract UniswapV2Factory is IUniswapV2Factory {
	error Forbidden();
	error PairExistsAlready();
	error IdenticalCurrencies();
	error InvalidCurrency();

	address public feeTo;
	address public feeToSetter;

	mapping(Currency currencyA => mapping(Currency currencyB => address pair)) private _pairs;
	address[] private _allPairs;

	constructor(address _feeToSetter) {
		feeToSetter = _feeToSetter;
	}

	function getPair(Currency currencyA, Currency currencyB) external view returns (address) {
		return _pairs[currencyA][currencyB];
	}

	function allPairs(uint256 index) external view returns (address) {
		return _allPairs[index];
	}

	function allPairsLength() external view returns (uint256) {
		return _allPairs.length;
	}

	function createPair(Currency currencyA, Currency currencyB) external returns (address pair) {
		(Currency currency0, Currency currency1) = currencyA < currencyB
			? (currencyA, currencyB)
			: (currencyB, currencyA);

		if (currency0 == currency1) revert IdenticalCurrencies();
		if (currency0.isZero()) revert InvalidCurrency();
		if (_pairs[currency0][currency1] != address(0)) revert PairExistsAlready();

		pair = _createPair(currency0, currency1);

		_pairs[currency0][currency1] = pair;
		_pairs[currency1][currency0] = pair;
		_allPairs.push(pair);

		emit PairCreated(currency0, currency1, pair, _allPairs.length);
	}

	function _createPair(Currency currency0, Currency currency1) internal virtual returns (address pair) {
		bytes memory bytecode = type(UniswapV2Pair).creationCode;

		bytes32 salt = keccak256(abi.encodePacked(currency0, currency1));

		assembly ("memory-safe") {
			pair := create2(0x00, add(bytecode, 0x20), mload(bytecode), salt)

			if iszero(pair) {
				mstore(0x00, 0xe1745f83) // PairCreationFailed()
				revert(0x1c, 0x04)
			}
		}

		IUniswapV2Pair(pair).initialize(currency0, currency1);
	}

	function setFeeTo(address _feeTo) external {
		if (msg.sender != feeToSetter) revert Forbidden();
		feeTo = _feeTo;
	}

	function setFeeToSetter(address _feeToSetter) external {
		if (msg.sender != feeToSetter) revert Forbidden();
		feeToSetter = _feeToSetter;
	}
}

contract CUniswapV2Factory is UniswapV2Factory {
	constructor(address _feeToSetter) UniswapV2Factory(_feeToSetter) {}

	function _createPair(Currency currency0, Currency currency1) internal virtual override returns (address pair) {
		bytes memory bytecode = abi.encodePacked(type(CUniswapV2Pair).creationCode, abi.encode(currency0, currency1));

		bytes32 salt = keccak256(abi.encodePacked(currency0, currency1));

		assembly ("memory-safe") {
			pair := create2(0x00, add(bytecode, 0x20), mload(bytecode), salt)

			if iszero(pair) {
				mstore(0x00, 0xe1745f83) // PairCreationFailed()
				revert(0x1c, 0x04)
			}
		}
	}
}

interface IUniswapV2PairDeployer {
	function parameters() external view returns (Currency currency0, Currency currency1);
}

contract TUniswapV2Factory is IUniswapV2PairDeployer, UniswapV2Factory {
	// bytes32(uint256(keccak256("UniswapV2Factory.pairContext.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant PAIR_CONTEXT_SLOT = 0x7795f0288f84ebc3248ba2ece8a261d88f3c68aa04c040b6eed48a2eafe53400;

	constructor(address _feeToSetter) UniswapV2Factory(_feeToSetter) {}

	function parameters() external view returns (Currency currency0, Currency currency1) {
		assembly ("memory-safe") {
			if iszero(tload(PAIR_CONTEXT_SLOT)) {
				mstore(0x00, 0xce174065) // SlotEmpty()
				revert(0x1c, 0x04)
			}

			currency0 := tload(PAIR_CONTEXT_SLOT)
			currency1 := tload(add(PAIR_CONTEXT_SLOT, 0x01))
		}
	}

	function _createPair(Currency currency0, Currency currency1) internal virtual override returns (address pair) {
		bytes memory bytecode = type(TUniswapV2Pair).creationCode;

		bytes32 salt = keccak256(abi.encodePacked(currency0, currency1));

		assembly ("memory-safe") {
			if iszero(iszero(tload(PAIR_CONTEXT_SLOT))) {
				mstore(0x00, 0x55b9fb08) // SlotNotEmpty()
				revert(0x1c, 0x04)
			}

			tstore(PAIR_CONTEXT_SLOT, currency0)
			tstore(add(PAIR_CONTEXT_SLOT, 0x01), currency1)

			pair := create2(0x00, add(bytecode, 0x20), mload(bytecode), salt)

			if iszero(pair) {
				mstore(0x00, 0xe1745f83) // PairCreationFailed()
				revert(0x1c, 0x04)
			}

			tstore(PAIR_CONTEXT_SLOT, 0x00)
			tstore(add(PAIR_CONTEXT_SLOT, 0x01), 0x00)
		}
	}
}
