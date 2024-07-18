// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Lock
/// @notice Provides functions to determine whether this contract is currently locked or not

library Lock {
	// bytes32(uint256(keccak256("Lock.locked.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 internal constant LOCKED_SLOT = 0x2caa6f45d4794176a6f95d83a89e8f0a508b9c23996e84caaa5db6d3ba7c2e00;

	function lock() internal {
		assembly ("memory-safe") {
			if iszero(iszero(tload(LOCKED_SLOT))) {
				mstore(0x00, 0x0f2e5b6c) // Locked()
				revert(0x1c, 0x04)
			}

			tstore(LOCKED_SLOT, 0x01)
		}
	}

	function unlock() internal {
		assembly ("memory-safe") {
			tstore(LOCKED_SLOT, 0x00)
		}
	}

	function lock(bytes32 slot) internal {
		assembly ("memory-safe") {
			if iszero(iszero(tload(slot))) {
				mstore(0x00, 0x0f2e5b6c) // Locked()
				revert(0x1c, 0x04)
			}

			tstore(slot, 0x01)
		}
	}

	function unlock(bytes32 slot) internal {
		assembly ("memory-safe") {
			tstore(slot, 0x00)
		}
	}

	function isLocked() internal view returns (bool locked) {
		assembly ("memory-safe") {
			locked := iszero(iszero(tload(LOCKED_SLOT)))
		}
	}
}
