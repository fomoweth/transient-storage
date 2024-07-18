// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Currency} from "src/types/Currency.sol";
import {Assertion} from "./Assertion.sol";
import {Constants} from "./Constants.sol";

abstract contract Common is CommonBase, Assertion, Constants, StdCheats {
	function fork(bool forkOnBlock) internal {
		uint256 forkBlock;
		if (forkOnBlock) forkBlock = vm.envOr("FORK_BLOCK_ETHEREUM", forkBlock);

		if (forkBlock != 0) {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"), forkBlock);
		} else {
			vm.createSelectFork(vm.envString("RPC_ETHEREUM"));
		}
	}

	function deal(Currency currency, uint256 amount) internal {
		deal(currency, address(this), amount);
	}

	function deal(Currency currency, address account, uint256 amount) internal {
		deal(Currency.unwrap(currency), account, amount);
	}

	function encodePrivateKey(string memory desc) internal pure returns (uint256 privateKey) {
		return uint256(keccak256(abi.encodePacked(desc)));
	}
}
