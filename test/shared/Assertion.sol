// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StdAssertions} from "forge-std/StdAssertions.sol";
import {Currency} from "src/types/Currency.sol";

abstract contract Assertion is StdAssertions {
	function assertEq(Currency result, Currency expected) internal pure {
		assertEq(Currency.unwrap(result), Currency.unwrap(expected));
	}

	function assertEq(Currency result, Currency expected, string memory err) internal pure {
		assertEq(Currency.unwrap(result), Currency.unwrap(expected), err);
	}

	function assertEq(Currency[] memory result, Currency[] memory expected) internal pure {
		assertEq(result, expected, "");
	}

	function assertEq(Currency[] memory result, Currency[] memory expected, string memory err) internal pure {
		address[] memory unwrappedResult;
		address[] memory unwrappedExpected;

		assembly ("memory-safe") {
			unwrappedResult := result
			unwrappedExpected := expected
		}

		assertEq(unwrappedResult, unwrappedExpected, err);
	}
}
