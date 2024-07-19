// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title ReentrancyGuardTransient
/// @notice Prevents reentrant calls to a function

abstract contract ReentrancyGuardTransient {
	// keccak256(abi.encode(uint256(keccak256("ReentrancyGuard.storage.tslot")) - 1)) & ~bytes32(uint256(0xff))
	bytes32 private constant REENTRANCY_GUARD_TSLOT =
		0x7fa101c675504f300024665bb98368fa249f0de168a726bc582d6a21883adf00;

	modifier nonReentrant() {
		_nonReentrantEnter();
		_;
		_nonReentrantExit();
	}

	function _nonReentrantEnter() private {
		assembly ("memory-safe") {
			if iszero(iszero(tload(REENTRANCY_GUARD_TSLOT))) {
				mstore(0x00, 0x37ed32e8) // ReentrantCall()
				revert(0x1c, 0x04)
			}

			tstore(REENTRANCY_GUARD_TSLOT, 0x01)
		}
	}

	function _nonReentrantExit() private {
		assembly ("memory-safe") {
			tstore(REENTRANCY_GUARD_TSLOT, 0x00)
		}
	}

	function _isEntered() internal view virtual returns (bool status) {
		assembly ("memory-safe") {
			status := iszero(iszero(tload(REENTRANCY_GUARD_TSLOT)))
		}
	}
}
