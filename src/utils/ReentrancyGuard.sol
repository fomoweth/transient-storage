// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title ReentrancyGuard
/// @notice Prevents reentrant calls to a function

abstract contract ReentrancyGuard {
	// keccak256(abi.encode(uint256(keccak256("ReentrancyGuard.storage.slot")) - 1)) & ~bytes32(uint256(0xff))
	bytes32 private constant REENTRANCY_GUARD_SLOT = 0x5470633104b80b94375cd178c94c32a3ce7c3ceba714e8fbc1a76bad1d388500;

	uint256 private constant NOT_ENTERED = 1;
	uint256 private constant ENTERED = 2;

	modifier nonReentrant() {
		_nonReentrantEnter();
		_;
		_nonReentrantExit();
	}

	constructor() {
		_nonReentrantExit();
	}

	function _nonReentrantEnter() private {
		assembly ("memory-safe") {
			if eq(sload(REENTRANCY_GUARD_SLOT), ENTERED) {
				mstore(0x00, 0x37ed32e8) // ReentrantCall()
				revert(0x1c, 0x04)
			}

			sstore(REENTRANCY_GUARD_SLOT, ENTERED)
		}
	}

	function _nonReentrantExit() private {
		assembly ("memory-safe") {
			sstore(REENTRANCY_GUARD_SLOT, NOT_ENTERED)
		}
	}

	function _isEntered() internal view virtual returns (bool status) {
		assembly ("memory-safe") {
			status := eq(sload(REENTRANCY_GUARD_SLOT), ENTERED)
		}
	}
}
