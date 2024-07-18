// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title Math
/// @notice Provides functions to handle unsigned math operations

library Math {
	uint256 internal constant WAD = 1e18;

	function ternary(bool condition, uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(y, mul(xor(x, y), iszero(iszero(condition))))
		}
	}

	function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), gt(y, x)))
		}
	}

	function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(x, mul(xor(x, y), lt(y, x)))
		}
	}

	function dist(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := xor(mul(xor(sub(y, x), sub(x, y)), gt(x, y)), sub(y, x))
		}
	}

	function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := mod(x, y)
		}
	}

	function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
		unchecked {
			z = x + y;
		}
	}

	function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
		unchecked {
			z = x - y;
		}
	}

	function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		unchecked {
			z = x * y;
		}
	}

	function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := div(x, y)
		}
	}

	function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := add(div(x, y), gt(mod(x, y), 0))
		}
	}

	function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			let mm := mulmod(x, y, not(0))
			let p0 := mul(x, y)
			let p1 := sub(sub(mm, p0), lt(mm, p0))

			if iszero(gt(d, p1)) {
				invalid()
			}

			switch iszero(p1)
			case 0x00 {
				let r := mulmod(x, y, d)
				p1 := sub(p1, gt(r, p0))
				p0 := sub(p0, r)

				let t := and(d, sub(0, d))
				d := div(d, t)

				let inv := xor(2, mul(3, d))

				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
				inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**256

				z := mul(or(mul(p1, add(div(sub(0, t), t), 1)), div(p0, t)), inv)
			}
			default {
				z := div(p0, d)
			}
		}
	}

	function mulDivRoundingUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
		z = mulDiv(x, y, d);

		assembly ("memory-safe") {
			if mulmod(x, y, d) {
				if iszero(lt(z, not(0))) {
					invalid()
				}

				z := add(z, 1)
			}
		}
	}

	function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			switch x
			case 0 {
				z := mul(b, iszero(y))
			}
			default {
				z := xor(b, mul(xor(b, x), and(y, 1)))
				let half := shr(1, b)

				// prettier-ignore
				for { y := shr(1, y) } y { y := shr(1, y) } {
					let xx := mul(x, x)
					let xxRound := add(xx, half)

					if or(lt(xxRound, xx), shr(128, x)) {
						mstore(0x00, 0x35278d12) // Overflow()
						revert(0x1c, 0x04)
					}

					x := div(xxRound, b)

					if and(y, 1) {
						let zx := mul(z, x)
						let zxRound := add(zx, half)

						if or(xor(div(zx, x), z), lt(zxRound, zx)) {
							if iszero(iszero(x)) {
								mstore(0x00, 0x35278d12) // Overflow()
								revert(0x1c, 0x04)
							}
						}

						z := div(zxRound, b)
					}
				}
			}
		}
	}

	function sqrt(uint256 x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := 181

			let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
			r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
			r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
			r := or(r, shl(4, lt(0xffffff, shr(r, x))))
			z := shl(shr(1, r), z)

			z := shr(18, mul(z, add(shr(r, x), 65536)))

			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))

			z := sub(z, lt(div(x, z), z))
		}
	}

	function wadMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if mul(y, gt(x, div(not(0), y))) {
				invalid()
			}

			z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
		}
	}

	function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
				invalid()
			}

			z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
		}
	}

	function derive(
		uint256 baseAnswer,
		uint256 quoteAnswer,
		uint8 baseDecimals,
		uint8 quoteDecimals,
		uint8 decimals
	) internal pure returns (uint256 derived) {
		unchecked {
			if (baseAnswer != 0 && quoteAnswer != 0) {
				derived = mulDiv(
					scale(baseAnswer, baseDecimals, decimals),
					10 ** decimals,
					scale(quoteAnswer, quoteDecimals, decimals)
				);
			}
		}
	}

	function inverse(uint256 answer, uint8 baseDecimals, uint8 quoteDecimals) internal pure returns (uint256 inversed) {
		assembly ("memory-safe") {
			if iszero(iszero(answer)) {
				inversed := div(exp(10, add(baseDecimals, quoteDecimals)), answer)
			}
		}
	}

	function scale(uint256 answer, uint8 baseDecimals, uint8 quoteDecimals) internal pure returns (uint256 scaled) {
		assembly ("memory-safe") {
			function ternary(condition, a, b) -> c {
				c := xor(b, mul(xor(a, b), iszero(iszero(condition))))
			}

			scaled := ternary(
				and(iszero(iszero(answer)), xor(baseDecimals, quoteDecimals)),
				ternary(
					lt(baseDecimals, quoteDecimals),
					mul(answer, exp(10, sub(quoteDecimals, baseDecimals))),
					div(answer, exp(10, sub(baseDecimals, quoteDecimals)))
				),
				answer
			)
		}
	}
}
