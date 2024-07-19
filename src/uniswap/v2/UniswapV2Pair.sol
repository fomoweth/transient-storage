// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV2Pair} from "src/interfaces/v2/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "src/interfaces/v2/IUniswapV2Factory.sol";
import {IUniswapV2Callee} from "src/interfaces/v2/IUniswapV2Callee.sol";
import {Lock} from "src/libraries/Lock.sol";
import {Math} from "src/libraries/Math.sol";
import {SafeCast} from "src/libraries/SafeCast.sol";
import {UQ112x112} from "src/libraries/UQ112x112.sol";
import {Currency} from "src/types/Currency.sol";
import {IUniswapV2PairDeployer} from "./UniswapV2Factory.sol";
import {UniswapV2ERC20} from "./UniswapV2ERC20.sol";

contract UniswapV2PairInitializer is IUniswapV2Pair, UniswapV2ERC20 {
	using SafeCast for uint256;
	using UQ112x112 for uint224;

	uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

	address private _factory;
	Currency private _token0;
	Currency private _token1;

	uint112 private _reserve0;
	uint112 private _reserve1;
	uint32 private _blockTimestampLast;

	uint256 private _price0CumulativeLast;
	uint256 private _price1CumulativeLast;
	uint256 private _kLast;

	modifier lock() {
		Lock.lock();
		_;
		Lock.unlock();
	}

	constructor() {
		_factory = msg.sender;
	}

	function factory() public view returns (address) {
		return _factory;
	}

	function token0() public view returns (Currency) {
		return _token0;
	}

	function token1() public view returns (Currency) {
		return _token1;
	}

	function getReserves() public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
		reserve0 = _reserve0;
		reserve1 = _reserve1;
		blockTimestampLast = _blockTimestampLast;
	}

	function price0CumulativeLast() public view returns (uint256) {
		return _price0CumulativeLast;
	}

	function price1CumulativeLast() public view returns (uint256) {
		return _price1CumulativeLast;
	}

	function kLast() public view returns (uint256) {
		return _kLast;
	}

	function initialize(Currency currency0, Currency currency1) external {
		if (msg.sender != factory()) revert Forbidden();
		_token0 = currency0;
		_token1 = currency1;
	}

	function mint(address recipient) external lock returns (uint256 liquidity) {
		(uint112 reserve0, uint112 reserve1, ) = getReserves();

		uint256 balance0 = _balance(token0());
		uint256 balance1 = _balance(token1());

		uint256 amount0;
		uint256 amount1;

		unchecked {
			amount0 = balance0 - reserve0;
			amount1 = balance1 - reserve1;
		}

		bool feeOn = _mintFee(reserve0, reserve1);
		uint256 totalSupply = totalSupply();

		if (totalSupply != 0) {
			liquidity = Math.min((amount0 * totalSupply) / reserve0, (amount1 * totalSupply) / reserve1);
		} else {
			liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
			_mint(address(0), MINIMUM_LIQUIDITY);
		}

		if (liquidity == 0) revert InsufficientLiquidityMinted();

		_mint(recipient, liquidity);
		_update(balance0, balance1, reserve0, reserve1);

		if (feeOn) _kLast = reserve0 * reserve1;

		emit Mint(msg.sender, amount0, amount1);
	}

	function burn(address recipient) external lock returns (uint256 amount0, uint256 amount1) {
		(uint112 reserve0, uint112 reserve1, ) = getReserves();

		Currency currency0 = token0();
		Currency currency1 = token1();

		uint256 balance0 = _balance(currency0);
		uint256 balance1 = _balance(currency1);
		uint256 liquidity = balanceOf(address(this));

		bool feeOn = _mintFee(reserve0, reserve1);
		uint256 totalSupply = totalSupply();

		if (
			(amount0 = (liquidity * balance0) / totalSupply) == 0 ||
			(amount1 = (liquidity * balance1) / totalSupply) == 0
		) {
			revert InsufficientLiquidityBurned();
		}

		_burn(address(this), liquidity);
		_transfer(currency0, recipient, amount0);
		_transfer(currency1, recipient, amount1);

		balance0 = _balance(currency0);
		balance1 = _balance(currency1);

		_update(balance0, balance1, reserve0, reserve1);

		if (feeOn) _kLast = reserve0 * reserve1;

		emit Burn(msg.sender, amount0, amount1, recipient);
	}

	function swap(uint256 amount0Out, uint256 amount1Out, address recipient, bytes calldata data) external lock {
		if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();

		(uint112 reserve0, uint112 reserve1, ) = getReserves();

		if (amount0Out >= reserve0 || amount1Out >= reserve1) revert InsufficientLiquidity();

		uint256 balance0;
		uint256 balance1;

		{
			Currency currency0 = token0();
			Currency currency1 = token1();

			if (recipient == Currency.unwrap(currency0) || recipient == Currency.unwrap(currency1)) {
				revert InvalidRecipient();
			}

			if (amount0Out != 0) _transfer(currency0, recipient, amount0Out);
			if (amount1Out != 0) _transfer(currency1, recipient, amount1Out);
			if (data.length != 0) IUniswapV2Callee(recipient).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

			balance0 = _balance(currency0);
			balance1 = _balance(currency1);
		}

		uint256 amount0In;
		uint256 amount1In;

		unchecked {
			uint256 delta0 = reserve0 - amount0Out;
			uint256 delta1 = reserve1 - amount1Out;

			if (balance0 > delta0) amount0In = balance0 - delta0;
			if (balance1 > delta1) amount1In = balance1 - delta1;

			if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();
		}

		{
			uint256 adjusted0 = balance0 * 1000 - (amount0In * 3);
			uint256 adjusted1 = balance1 * 1000 - (amount1In * 3);

			if (adjusted0 * adjusted1 < reserve0 * reserve1 * (1000 ** 2)) revert K();
		}

		_update(balance0, balance1, reserve0, reserve1);

		emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, recipient);
	}

	function skim(address recipient) external lock {
		Currency currency0 = token0();
		Currency currency1 = token1();

		_transfer(currency0, recipient, _balance(currency0) - _reserve0);
		_transfer(currency1, recipient, _balance(currency1) - _reserve1);
	}

	function sync() external lock {
		_update(_balance(token0()), _balance(token1()), _reserve0, _reserve1);
	}

	function _mintFee(uint112 reserve0, uint112 reserve1) private returns (bool feeOn) {
		address feeTo = IUniswapV2Factory(factory()).feeTo();

		uint256 kLast_ = _kLast;

		if ((feeOn = feeTo != address(0))) {
			if (kLast_ != 0) {
				uint256 rootK = Math.sqrt(reserve0 * reserve1);
				uint256 rootKLast = Math.sqrt(kLast_);

				if (rootK > rootKLast) {
					uint256 numerator = totalSupply() * (rootK - rootKLast);
					uint256 denominator = (rootK * 5) + rootKLast;
					uint256 liquidity = numerator / denominator;

					if (liquidity != 0) _mint(feeTo, liquidity);
				}
			}
		} else if (kLast_ != 0) {
			_kLast = 0;
		}
	}

	function _update(uint256 balance0, uint256 balance1, uint112 reserve0, uint112 reserve1) private {
		uint32 blockTimestamp = block.timestamp.toUint32();
		uint32 timeElapsed;

		unchecked {
			timeElapsed = blockTimestamp - _blockTimestampLast;
		}

		if (timeElapsed != 0 && reserve0 != 0 && reserve1 != 0) {
			_price0CumulativeLast += uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
			_price1CumulativeLast += uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
		}

		_reserve0 = balance0.toUint112();
		_reserve1 = balance1.toUint112();
		_blockTimestampLast = blockTimestamp;

		emit Sync(reserve0, reserve1);
	}

	function _transfer(Currency currency, address recipient, uint256 value) private {
		currency.transfer(recipient, value);
	}

	function _balance(Currency currency) private view returns (uint256) {
		return currency.balanceOfSelf();
	}
}

abstract contract UniswapV2PairImmutable is IUniswapV2Pair, UniswapV2ERC20 {
	using SafeCast for uint256;
	using UQ112x112 for uint224;

	uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

	address public immutable factory;
	Currency public immutable token0;
	Currency public immutable token1;

	uint112 private _reserve0;
	uint112 private _reserve1;
	uint32 private _blockTimestampLast;

	uint256 private _price0CumulativeLast;
	uint256 private _price1CumulativeLast;
	uint256 private _kLast;

	modifier lock() {
		Lock.lock();
		_;
		Lock.unlock();
	}

	constructor() {
		factory = msg.sender;
	}

	function getReserves() public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
		reserve0 = _reserve0;
		reserve1 = _reserve1;
		blockTimestampLast = _blockTimestampLast;
	}

	function price0CumulativeLast() public view returns (uint256) {
		return _price0CumulativeLast;
	}

	function price1CumulativeLast() public view returns (uint256) {
		return _price1CumulativeLast;
	}

	function kLast() public view returns (uint256) {
		return _kLast;
	}

	function initialize(Currency, Currency) external virtual {
		if (msg.sender != factory) revert Forbidden();
	}

	function mint(address recipient) external lock returns (uint256 liquidity) {
		uint112 reserve0 = _reserve0;
		uint112 reserve1 = _reserve1;

		uint256 balance0 = _balance0();
		uint256 balance1 = _balance1();

		uint256 amount0;
		uint256 amount1;

		unchecked {
			amount0 = balance0 - reserve0;
			amount1 = balance1 - reserve1;
		}

		bool feeOn = _mintFee(reserve0, reserve1);
		uint256 totalSupply = totalSupply();

		if (totalSupply != 0) {
			liquidity = Math.min((amount0 * totalSupply) / reserve0, (amount1 * totalSupply) / reserve1);
		} else {
			liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
			_mint(address(0), MINIMUM_LIQUIDITY);
		}

		if (liquidity == 0) revert InsufficientLiquidityMinted();

		_mint(recipient, liquidity);
		_update(balance0, balance1, reserve0, reserve1);

		if (feeOn) _kLast = reserve0 * reserve1;

		emit Mint(msg.sender, amount0, amount1);
	}

	function burn(address recipient) external lock returns (uint256 amount0, uint256 amount1) {
		uint112 reserve0 = _reserve0;
		uint112 reserve1 = _reserve1;

		uint256 balance0 = _balance0();
		uint256 balance1 = _balance1();
		uint256 liquidity = balanceOf(address(this));

		bool feeOn = _mintFee(reserve0, reserve1);
		uint256 totalSupply = totalSupply();

		if (
			(amount0 = (liquidity * balance0) / totalSupply) == 0 ||
			(amount1 = (liquidity * balance1) / totalSupply) == 0
		) {
			revert InsufficientLiquidityBurned();
		}

		_burn(address(this), liquidity);
		_transfer0(recipient, amount0);
		_transfer1(recipient, amount1);

		balance0 = _balance0();
		balance1 = _balance1();

		_update(balance0, balance1, reserve0, reserve1);
		if (feeOn) _kLast = reserve0 * reserve1;

		emit Burn(msg.sender, amount0, amount1, recipient);
	}

	function swap(uint256 amount0Out, uint256 amount1Out, address recipient, bytes calldata data) external lock {
		if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();

		uint112 reserve0 = _reserve0;
		uint112 reserve1 = _reserve1;

		if (amount0Out >= reserve0 || amount1Out >= reserve1) revert InsufficientLiquidity();

		{
			if (recipient == Currency.unwrap(token0) || recipient == Currency.unwrap(token1)) {
				revert InvalidRecipient();
			}

			if (amount0Out != 0) _transfer0(recipient, amount0Out);
			if (amount1Out != 0) _transfer1(recipient, amount1Out);
			if (data.length != 0) IUniswapV2Callee(recipient).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
		}

		uint256 balance0 = _balance0();
		uint256 balance1 = _balance1();

		uint256 amount0In;
		uint256 amount1In;

		unchecked {
			uint256 delta0 = reserve0 - amount0Out;
			uint256 delta1 = reserve1 - amount1Out;

			if (balance0 > delta0) amount0In = balance0 - delta0;
			if (balance1 > delta1) amount1In = balance1 - delta1;

			if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();
		}

		{
			uint256 adjusted0 = balance0 * 1000 - (amount0In * 3);
			uint256 adjusted1 = balance1 * 1000 - (amount1In * 3);

			if (adjusted0 * adjusted1 < reserve0 * reserve1 * (1000 ** 2)) revert K();
		}

		_update(balance0, balance1, reserve0, reserve1);

		emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, recipient);
	}

	function skim(address recipient) external lock {
		_transfer0(recipient, _balance0() - _reserve0);
		_transfer1(recipient, _balance1() - _reserve1);
	}

	function sync() external lock {
		_update(_balance0(), _balance1(), _reserve0, _reserve1);
	}

	function _mintFee(uint112 reserve0, uint112 reserve1) private returns (bool feeOn) {
		address feeTo = IUniswapV2Factory(factory).feeTo();

		uint256 kLast_ = _kLast;

		if ((feeOn = feeTo != address(0))) {
			if (kLast_ != 0) {
				uint256 rootK = Math.sqrt(reserve0 * reserve1);
				uint256 rootKLast = Math.sqrt(kLast_);

				if (rootK > rootKLast) {
					uint256 numerator = totalSupply() * (rootK - rootKLast);
					uint256 denominator = (rootK * 5) + rootKLast;
					uint256 liquidity = numerator / denominator;

					if (liquidity != 0) _mint(feeTo, liquidity);
				}
			}
		} else if (kLast_ != 0) {
			_kLast = 0;
		}
	}

	function _update(uint256 balance0, uint256 balance1, uint112 reserve0, uint112 reserve1) private {
		uint32 blockTimestamp = block.timestamp.toUint32();
		uint32 timeElapsed;

		unchecked {
			timeElapsed = blockTimestamp - _blockTimestampLast;
		}

		if (timeElapsed != 0 && reserve0 != 0 && reserve1 != 0) {
			_price0CumulativeLast += uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
			_price1CumulativeLast += uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
		}

		_reserve0 = balance0.toUint112();
		_reserve1 = balance1.toUint112();
		_blockTimestampLast = blockTimestamp;

		emit Sync(reserve0, reserve1);
	}

	function _transfer0(address recipient, uint256 value) private {
		token0.transfer(recipient, value);
	}

	function _transfer1(address recipient, uint256 value) private {
		token1.transfer(recipient, value);
	}

	function _balance0() private view returns (uint256) {
		return token0.balanceOfSelf();
	}

	function _balance1() private view returns (uint256) {
		return token1.balanceOfSelf();
	}
}

contract UniswapV2PairConstructor is UniswapV2PairImmutable {
	constructor(Currency currency0, Currency currency1) {
		token0 = currency0;
		token1 = currency1;
	}
}

contract UniswapV2PairTransient is UniswapV2PairImmutable {
	constructor() {
		(Currency currency0, Currency currency1) = IUniswapV2PairDeployer(msg.sender).parameters();

		token0 = currency0;
		token1 = currency1;
	}
}
