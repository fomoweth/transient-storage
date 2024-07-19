// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

abstract contract Constants {
	bytes32 constant UNISWAP_V2_PAIR_INIT_CODE_HASH =
		0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;

	address constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

	bytes32 constant UNISWAP_V3_POOL_INIT_CODE_HASH =
		0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

	address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

	uint24 constant FEE_LOWEST = 100;
	uint24 constant FEE_LOW = 500;
	uint24 constant FEE_MEDIUM = 3000;
	uint24 constant FEE_HIGH = 10000;
}
