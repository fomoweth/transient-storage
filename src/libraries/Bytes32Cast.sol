// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Currency} from "src/types/Currency.sol";

/// @title Bytes32Cast

library Bytes32Cast {
	function castToBytes32(bool input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bool[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBool(bytes32 input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBool(bytes32[] memory input) internal pure returns (bool[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(address input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(address[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToAddress(bytes32 input) internal pure returns (address output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToAddress(bytes32[] memory input) internal pure returns (address[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(Currency input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToCurrency(bytes32 input) internal pure returns (Currency output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(Currency[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToCurrency(bytes32[] memory input) internal pure returns (Currency[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(uint256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(uint256[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint256(bytes32 input) internal pure returns (uint256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToUint256(bytes32[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(int256 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(int256[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToInt256(bytes32 input) internal pure returns (int256 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToInt256(bytes32[] memory input) internal pure returns (int256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes1 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes1(bytes32 input) internal pure returns (bytes1 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes1[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes1(bytes32[] memory input) internal pure returns (bytes1[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes2 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes2(bytes32 input) internal pure returns (bytes2 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes2[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes2(bytes32[] memory input) internal pure returns (bytes2[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes3 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes3(bytes32 input) internal pure returns (bytes3 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes3[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes3(bytes32[] memory input) internal pure returns (bytes3[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes4 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes4(bytes32 input) internal pure returns (bytes4 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes4[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes4(bytes32[] memory input) internal pure returns (bytes4[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes5 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes5(bytes32 input) internal pure returns (bytes5 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes5[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes5(bytes32[] memory input) internal pure returns (bytes5[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes6 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes6(bytes32 input) internal pure returns (bytes6 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes6[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes6(bytes32[] memory input) internal pure returns (bytes6[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes7 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes7(bytes32 input) internal pure returns (bytes7 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes7[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes7(bytes32[] memory input) internal pure returns (bytes7[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes8 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes8(bytes32 input) internal pure returns (bytes8 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes8[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes8(bytes32[] memory input) internal pure returns (bytes8[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes9 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes9(bytes32 input) internal pure returns (bytes9 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes9[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes9(bytes32[] memory input) internal pure returns (bytes9[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes10 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes10(bytes32 input) internal pure returns (bytes10 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes10[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes10(bytes32[] memory input) internal pure returns (bytes10[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes11 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes11(bytes32 input) internal pure returns (bytes11 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes11[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes11(bytes32[] memory input) internal pure returns (bytes11[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes12 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes12(bytes32 input) internal pure returns (bytes12 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes12[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes12(bytes32[] memory input) internal pure returns (bytes12[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes13 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes13(bytes32 input) internal pure returns (bytes13 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes13[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes13(bytes32[] memory input) internal pure returns (bytes13[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes14 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes14(bytes32 input) internal pure returns (bytes14 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes14[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes14(bytes32[] memory input) internal pure returns (bytes14[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes15 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes15(bytes32 input) internal pure returns (bytes15 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes15[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes15(bytes32[] memory input) internal pure returns (bytes15[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes16 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes16(bytes32 input) internal pure returns (bytes16 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes16[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes16(bytes32[] memory input) internal pure returns (bytes16[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes17 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes17(bytes32 input) internal pure returns (bytes17 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes17[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes17(bytes32[] memory input) internal pure returns (bytes17[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes18 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes18(bytes32 input) internal pure returns (bytes18 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes18[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes18(bytes32[] memory input) internal pure returns (bytes18[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes19 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes19(bytes32 input) internal pure returns (bytes19 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes19[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes19(bytes32[] memory input) internal pure returns (bytes19[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes20 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes20(bytes32 input) internal pure returns (bytes20 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes20[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes20(bytes32[] memory input) internal pure returns (bytes20[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes21 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes21(bytes32 input) internal pure returns (bytes21 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes21[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes21(bytes32[] memory input) internal pure returns (bytes21[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes22 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes22(bytes32 input) internal pure returns (bytes22 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes22[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes22(bytes32[] memory input) internal pure returns (bytes22[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes23 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes23(bytes32 input) internal pure returns (bytes23 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes23[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes23(bytes32[] memory input) internal pure returns (bytes23[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes24 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes24(bytes32 input) internal pure returns (bytes24 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes24[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes24(bytes32[] memory input) internal pure returns (bytes24[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes25 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes25(bytes32 input) internal pure returns (bytes25 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes25[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes25(bytes32[] memory input) internal pure returns (bytes25[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes26 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes26(bytes32 input) internal pure returns (bytes26 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes26[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes26(bytes32[] memory input) internal pure returns (bytes26[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes27 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes27(bytes32 input) internal pure returns (bytes27 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes27[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes27(bytes32[] memory input) internal pure returns (bytes27[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes28 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes28(bytes32 input) internal pure returns (bytes28 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes28[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes28(bytes32[] memory input) internal pure returns (bytes28[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes29 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes29(bytes32 input) internal pure returns (bytes29 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes29[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes29(bytes32[] memory input) internal pure returns (bytes29[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes30 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes30(bytes32 input) internal pure returns (bytes30 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes30[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes30(bytes32[] memory input) internal pure returns (bytes30[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes31 input) internal pure returns (bytes32 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes31(bytes32 input) internal pure returns (bytes31 output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes32(bytes31[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	function castToBytes31(bytes32[] memory input) internal pure returns (bytes31[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}
}
