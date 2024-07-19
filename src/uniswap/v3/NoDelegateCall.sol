// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

abstract contract NoDelegateCall {
	address private immutable original;

	constructor() {
		original = address(this);
	}

	modifier noDelegateCall() {
		checkNotDelegateCall();
		_;
	}

	function checkNotDelegateCall() private view {
		require(address(this) == original);
	}
}
