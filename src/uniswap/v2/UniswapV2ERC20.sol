// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV2ERC20} from "src/interfaces/v2/IUniswapV2ERC20.sol";

contract UniswapV2ERC20 is IUniswapV2ERC20 {
	string public constant name = "Uniswap V2";

	string public constant symbol = "UNI-V2";

	uint8 public constant decimals = 18;

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
	bytes32 private constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

	bytes32 public immutable DOMAIN_SEPARATOR;

	uint256 private _totalSupply;

	mapping(address account => uint256 balance) private _balances;
	mapping(address owner => mapping(address spender => uint256 allowance)) private _allowances;
	mapping(address account => uint256 nonce) private _nonces;

	constructor() {
		uint256 chainId;
		assembly ("memory-safe") {
			chainId := chainid()
		}

		DOMAIN_SEPARATOR = keccak256(
			abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes("1")), chainId, address(this))
		);
	}

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function allowance(address owner, address spender) public view returns (uint256) {
		return _allowances[owner][spender];
	}

	function nonces(address owner) public view returns (uint256) {
		return _nonces[owner];
	}

	function transfer(address recipient, uint256 value) external returns (bool) {
		_transfer(msg.sender, recipient, value);

		return true;
	}

	function transferFrom(address sender, address recipient, uint256 value) external returns (bool) {
		_spendAllowance(sender, msg.sender, value);
		_transfer(sender, recipient, value);

		return true;
	}

	function approve(address spender, uint256 value) external returns (bool) {
		_approve(msg.sender, spender, value);

		return true;
	}

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		if (deadline < block.timestamp) revert DeadlineExpired();

		bytes32 domainSeparator = DOMAIN_SEPARATOR;

		bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

		bytes32 digest;

		assembly ("memory-safe") {
			let ptr := mload(0x40)
			mstore(ptr, hex"19_01")
			mstore(add(ptr, 0x02), domainSeparator)
			mstore(add(ptr, 0x22), structHash)
			digest := keccak256(ptr, 0x42)
		}

		address recovered = ecrecover(digest, v, r, s);
		if (recovered == address(0) || recovered != owner) revert InvalidSigner();

		_approve(owner, spender, value);
	}

	function _mint(address account, uint256 value) internal {
		if (account == address(0)) revert InvalidRecipient();

		_update(address(0), account, value);
	}

	function _burn(address account, uint256 value) internal {
		if (account == address(0)) revert InvalidSender();

		_update(account, address(0), value);
	}

	function _transfer(address sender, address recipient, uint256 value) private {
		if (sender == address(0)) revert InvalidSender();
		if (recipient == address(0)) revert InvalidRecipient();

		_update(sender, recipient, value);
	}

	function _update(address from, address to, uint256 value) private {
		if (from == address(0)) {
			_totalSupply = _totalSupply + value;
		} else {
			uint256 balance = _balances[from];
			if (balance < value) revert InsufficientBalance(from, balance, value);

			unchecked {
				_balances[from] = balance - value;
			}
		}

		unchecked {
			if (to == address(0)) {
				_totalSupply = _totalSupply - value;
			} else {
				_balances[to] = _balances[to] + value;
			}
		}

		emit Transfer(from, to, value);
	}

	function _approve(address owner, address spender, uint256 value) internal {
		_approve(owner, spender, value, true);
	}

	function _approve(address owner, address spender, uint256 value, bool emitEvent) private {
		if (owner == address(0)) revert InvalidApprover();
		if (spender == address(0)) revert InvalidSpender();

		_allowances[owner][spender] = value;

		if (emitEvent) emit Approval(owner, spender, value);
	}

	function _spendAllowance(address owner, address spender, uint256 value) private {
		uint256 currentAllowance = allowance(owner, spender);

		if (currentAllowance != type(uint256).max) {
			if (currentAllowance < value) revert InsufficientAllowance(spender, currentAllowance, value);

			unchecked {
				_approve(owner, spender, currentAllowance - value, false);
			}
		}
	}

	function _useNonce(address owner) private returns (uint256) {
		unchecked {
			return ++_nonces[owner];
		}
	}
}
