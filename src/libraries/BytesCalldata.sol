// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title BytesCalldata
/// @dev Implementation from https://github.com/Uniswap/universal-router/blob/main/contracts/modules/uniswap/v3/BytesLib.sol

library BytesCalldata {
	function toAddress(bytes calldata data) internal pure returns (address res) {
		assembly ("memory-safe") {
			if lt(data.length, 0x14) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := shr(0x60, calldataload(data.offset))
		}
	}

	function toAddressArray(bytes calldata data, uint256 index) internal pure returns (address[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toBytes32(bytes calldata data) internal pure returns (bytes32 res) {
		assembly ("memory-safe") {
			if lt(data.length, 0x20) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := calldataload(data.offset)
		}
	}

	function toBytes32Array(bytes calldata data, uint256 index) internal pure returns (bytes32[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toBytes(bytes calldata data, uint256 index) internal pure returns (bytes calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toBytesArray(bytes calldata data, uint256 index) internal pure returns (bytes[] calldata res) {
		(uint256 length, uint256 offset) = toLengthOffset(data, index);

		assembly ("memory-safe") {
			res.length := length
			res.offset := offset
		}
	}

	function toLengthOffset(bytes calldata data, uint256 index) internal pure returns (uint256 length, uint256 offset) {
		assembly ("memory-safe") {
			let lengthPtr := add(data.offset, calldataload(add(data.offset, shl(0x05, index))))
			length := calldataload(lengthPtr)
			offset := add(lengthPtr, 0x20)

			if lt(data.length, add(length, sub(offset, data.offset))) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}
		}
	}
}
