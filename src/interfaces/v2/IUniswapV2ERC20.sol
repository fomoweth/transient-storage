// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IUniswapV2ERC20 {
	event Approval(address indexed owner, address indexed spender, uint256 value);

	event Transfer(address indexed sender, address indexed recipient, uint256 value);

	error InsufficientAllowance(address spender, uint256 allowance, uint256 requested);

	error InsufficientBalance(address sender, uint256 balance, uint256 requested);

	error InvalidSender();

	error InvalidRecipient();

	error InvalidApprover();

	error InvalidSpender();

	error InvalidSigner();

	error DeadlineExpired();

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address recipient, uint256 value) external returns (bool);

	function transferFrom(address sender, address recipient, uint256 value) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}
