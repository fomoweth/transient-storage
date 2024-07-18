// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title BytesMemory
/// @dev Implementation from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/BytesLib.sol

library BytesMemory {
	function concat(bytes memory preBytes, bytes memory postBytes) internal pure returns (bytes memory res) {
		assembly ("memory-safe") {
			res := mload(0x40)

			let length := mload(preBytes)
			mstore(res, length)

			let mc := add(res, 0x20)
			let end := add(mc, length)

			for {
				let cc := add(preBytes, 0x20)
			} lt(mc, end) {
				mc := add(mc, 0x20)
				cc := add(cc, 0x20)
			} {
				mstore(mc, mload(cc))
			}

			length := mload(postBytes)
			mstore(res, add(length, mload(res)))

			mc := end
			end := add(mc, length)

			for {
				let cc := add(postBytes, 0x20)
			} lt(mc, end) {
				mc := add(mc, 0x20)
				cc := add(cc, 0x20)
			} {
				mstore(mc, mload(cc))
			}

			mstore(0x40, and(add(add(end, iszero(add(length, mload(preBytes)))), 0x1f), not(0x1f)))
		}
	}

	function slice(bytes memory data, uint256 offset, uint256 length) internal pure returns (bytes memory res) {
		assembly ("memory-safe") {
			if lt(add(length, 0x1f), length) {
				mstore(0x00, 0x47aaf07a) // SliceOverflow()
				revert(0x1c, 0x04)
			}

			if lt(mload(data), add(offset, length)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(0x40)

			switch iszero(length)
			case 0x00 {
				let lengthmod := and(length, 0x1f)
				let mc := add(add(res, lengthmod), mul(0x20, iszero(lengthmod)))
				let end := add(mc, length)

				for {
					let cc := add(add(add(data, lengthmod), mul(0x20, iszero(lengthmod))), offset)
				} lt(mc, end) {
					mc := add(mc, 0x20)
					cc := add(cc, 0x20)
				} {
					mstore(mc, mload(cc))
				}

				mstore(res, length)

				mstore(0x40, and(add(mc, 0x1f), not(0x1f)))
			}
			default {
				mstore(res, 0x00)
				mstore(0x40, add(res, 0x20))
			}
		}
	}

	function toAddress(bytes memory data, uint256 offset) internal pure returns (address res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x14)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := shr(0x60, mload(add(add(data, 0x20), offset)))
		}
	}

	function toUint8(bytes memory data, uint256 offset) internal pure returns (uint8 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x01)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x01), offset))
		}
	}

	function toUint16(bytes memory data, uint256 offset) internal pure returns (uint16 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x02)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x02), offset))
		}
	}

	function toUint24(bytes memory data, uint256 offset) internal pure returns (uint24 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x03)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x03), offset))
		}
	}

	function toUint32(bytes memory data, uint256 offset) internal pure returns (uint32 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x04)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x04), offset))
		}
	}

	function toUint64(bytes memory data, uint256 offset) internal pure returns (uint64 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x08)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x08), offset))
		}
	}

	function toUint96(bytes memory data, uint256 offset) internal pure returns (uint96 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x0c)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x0c), offset))
		}
	}

	function toUint128(bytes memory data, uint256 offset) internal pure returns (uint128 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x10)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x10), offset))
		}
	}

	function toUint160(bytes memory data, uint256 offset) internal pure returns (uint160 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x14)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x14), offset))
		}
	}

	function toUint256(bytes memory data, uint256 offset) internal pure returns (uint256 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x20)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x20), offset))
		}
	}

	function toBytes32(bytes memory data, uint256 offset) internal pure returns (bytes32 res) {
		assembly ("memory-safe") {
			if lt(mload(data), add(offset, 0x20)) {
				mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
				revert(0x1c, 0x04)
			}

			res := mload(add(add(data, 0x20), offset))
		}
	}
}
