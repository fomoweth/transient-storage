// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {ReentrancyGuard} from "src/utils/ReentrancyGuard.sol";
import {ReentrancyGuardTransient} from "src/utils/ReentrancyGuardTransient.sol";
import {Common} from "../shared/Common.sol";

contract MockReentrancyGuard is ReentrancyGuard {
	mapping(address account => uint256 balance) private _balances;

	function balanceOf(address account) external view virtual returns (uint256) {
		return _balances[account];
	}

	// 46045 gas
	function deposit(uint256 value) external payable virtual {
		_deposit(value);
	}

	function _deposit(uint256 value) internal virtual nonReentrant {
		require(value != 0);
		_balances[msg.sender] = _balances[msg.sender] + value;
	}

	receive() external payable {
		_deposit(msg.value);
	}
}

contract MockReentrancyGuardTransient is ReentrancyGuardTransient {
	mapping(address account => uint256 balance) private _balances;

	function balanceOf(address account) external view virtual returns (uint256) {
		return _balances[account];
	}

	// 44034 gas
	function deposit(uint256 value) external payable virtual {
		_deposit(value);
	}

	function _deposit(uint256 value) internal virtual nonReentrant {
		require(value != 0);
		_balances[msg.sender] = _balances[msg.sender] + value;
	}

	receive() external payable {
		_deposit(msg.value);
	}
}

contract ReentrancyGuardTest is Test, Common {
	address immutable SENDER = makeAddr("SENDER");

	MockReentrancyGuard mock;
	MockReentrancyGuardTransient tmock;

	function setUp() public {
		fork(true);

		mock = new MockReentrancyGuard();
		tmock = new MockReentrancyGuardTransient();
	}

	function test_reentrancyGuard(uint256 value) public {
		deal(SENDER, (value = bound(value, 1 ether, 100 ether)));

		uint256 balanceBefore = mock.balanceOf(SENDER);

		vm.prank(SENDER);

		mock.deposit{value: value}(value);

		uint256 balanceAfter = mock.balanceOf(SENDER);

		assertEq(balanceAfter - value, balanceBefore);
	}

	function test_reentrancyGuardTransient(uint256 value) public {
		deal(SENDER, (value = bound(value, 1 ether, 100 ether)));

		uint256 balanceBefore = tmock.balanceOf(SENDER);

		vm.prank(SENDER);

		tmock.deposit{value: value}(value);

		uint256 balanceAfter = tmock.balanceOf(SENDER);

		assertEq(balanceAfter - value, balanceBefore);
	}
}
