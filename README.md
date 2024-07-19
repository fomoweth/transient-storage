## [EIP-1153: Transient Storage](https://soliditylang.org/blog/2024/01/26/transient-storage)

Use cases of Transient Storage

### Constructing Uniswap V3 Pool

##### [UniswapV3Pool.sol](https://github.com/Uniswap/v3-core/blob/6562c52e8f75f0c10f9deaf44861847585fc8129/contracts/UniswapV3Pool.sol#L113)

```solidity
contract UniswapV3Pool {
	constructor() {
		int24 _tickSpacing;
        (factory, token0, token1, fee, _tickSpacing) = IUniswapV3PoolDeployer(msg.sender).parameters();
        tickSpacing = _tickSpacing;
        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
	}

	function initialize(uint160 sqrtPriceX96) external {
        require(slot0.sqrtPriceX96 == 0, 'AI');

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 0,
            unlocked: true
        });

        emit Initialize(sqrtPriceX96, tick);
    }
}
```

##### [UniswapV3PoolDeployer.sol](https://github.com/Uniswap/v3-core/blob/0.8/contracts/UniswapV3PoolDeployer.sol)

```solidity
contract UniswapV3PoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    Parameters public parameters;

    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());
        delete parameters;
    }
}
```

The pool parameters struct can be stored in transient storage and used to construct the immutable states of the pool.
Also the pool can be initialized inside of the constructor if necessary.

```solidity
contract UniswapV3Pool {
	constructor() {
		int24 _tickSpacing;
		uint160 sqrtPriceX96;
        (factory, token0, token1, fee, _tickSpacing, sqrtPriceX96) = IUniswapV3PoolDeployer(msg.sender).parameters();
        tickSpacing = _tickSpacing;
        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);

		int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

		(uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 0,
            unlocked: true
        });

		emit Initialize(sqrtPriceX96, tick);
	}
}

contract UniswapV3PoolDeployer {
	// bytes32(uint256(keccak256("UniswapV3Factory.poolContext.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant SLOT = 0x4cbc4600075b2f8c615834a56221934e92a9a18daaa9939c06932f192e907900;

	function deploy(
		address factory,
		address token0,
		address token1,
		uint24 fee,
		int24 tickSpacing,
		uint160 sqrtPriceX96
	) internal returns (address pool) {
		bytes memory bytecode = type(UniswapV3Pool).creationCode;

		bytes32 salt = keccak256(abi.encode(token0, token1, fee));

		assembly ("memory-safe") {
			if iszero(iszero(tload(SLOT))) {
				mstore(0x00, 0x55b9fb08) // SlotNotEmpty()
				revert(0x1c, 0x04)
			}

			tstore(SLOT, factory)
			tstore(add(SLOT, 0x20), token0)
			tstore(add(SLOT, 0x40), token1)
			tstore(add(SLOT, 0x60), fee)
			tstore(add(SLOT, 0x80), tickSpacing)
			tstore(add(SLOT, 0xa0), sqrtPriceX96)

			pool := create2(0x00, add(bytecode, 0x20), mload(bytecode), salt)

			if iszero(pool) {
				mstore(0x00, 0xdc802c74) // PoolCreationFailed()
				revert(0x1c, 0x04)
			}

			tstore(SLOT, 0x00)
			tstore(add(SLOT, 0x20), 0x00)
			tstore(add(SLOT, 0x40), 0x00)
			tstore(add(SLOT, 0x60), 0x00)
			tstore(add(SLOT, 0x80), 0x00)
			tstore(add(SLOT, 0xa0), 0x00)
		}
	}

	function parameters()
		external
		view
		returns (address factory, address token0, address token1, uint24 fee, int24 tickSpacing, uint160 sqrtPriceX96)
	{
		assembly ("memory-safe") {
			if iszero(tload(SLOT)) {
				mstore(0x00, 0xce174065) // SlotEmpty()
				revert(0x1c, 0x04)
			}

			factory := tload(SLOT)
			token0 := tload(add(SLOT, 0x20))
			token1 := tload(add(SLOT, 0x40))
			fee := tload(add(SLOT, 0x60))
			tickSpacing := tload(add(SLOT, 0x80))
			sqrtPriceX96 := tload(add(SLOT, 0xa0))
		}
	}
}
```

### Constructing Uniswap V2 Pair

##### [UniswapV2Pair.sol](https://github.com/Uniswap/v2-core/blob/ee547b17853e71ed4e0101ccfd52e70d5acded58/contracts/UniswapV2Pair.sol#L61)

```solidity
contract UniswapV2Pair {
	address public factory;
	address public token0;
	address public token1;

	constructor() {
		factory = msg.sender;
	}

	function initialize(address _token0, address _token1) external {
		require(msg.sender == factory, 'UniswapV2: FORBIDDEN');
		token0 = _token0;
		token1 = _token1;
	}
}
```

The Uniswap V2 `factory` and `pair` contracts can also be optimized similar to V3.

```solidity
contract UniswapV2Pair {
	address public immutable factory;
	address public immutable token0;
	address public immutable token1;

	constructor() {
		factory = msg.sender;
		(token0, token1) = IUniswapV2PairDeployer(msg.sender).parameters();
	}

	function initialize(address, address) external {
		revert();
	}
}

contract UniswapV2PairDeployer {
	// bytes32(uint256(keccak256("UniswapV2Factory.pairContext.slot")) - 1) & ~bytes32(uint256(0xff))
	bytes32 private constant SLOT = 0x7795f0288f84ebc3248ba2ece8a261d88f3c68aa04c040b6eed48a2eafe53400;

	function deploy(
		address token0,
		address token1
	) internal returns (address pair) {
		bytes memory bytecode = type(UniswapV2Pair).creationCode;

		bytes32 salt = keccak256(abi.encodePacked(token0, token1));

		assembly ("memory-safe") {
			if iszero(iszero(tload(SLOT))) {
				mstore(0x00, 0x55b9fb08) // SlotNotEmpty()
				revert(0x1c, 0x04)
			}

			tstore(SLOT, token0)
			tstore(add(SLOT, 0x20), token1)

			pair := create2(0x00, add(bytecode, 0x20), mload(bytecode), salt)

			if iszero(pair) {
				mstore(0x00, 0xe1745f83) // PairCreationFailed()
				revert(0x1c, 0x04)
			}

			tstore(SLOT, 0x00)
			tstore(add(SLOT, 0x20), 0x00)
		}
	}

	function parameters()
		external
		view
		returns (address token0, address token1)
	{
		assembly ("memory-safe") {
			if iszero(tload(SLOT)) {
				mstore(0x00, 0xce174065) // SlotEmpty()
				revert(0x1c, 0x04)
			}

			token0 := tload(SLOT)
			token1 := tload(add(SLOT, 0x20))
		}
	}
}
```

- `initialize` is no longer required to be called after the deployment.
- `factory`, `token0`, and `token1` are now immutable states which can save gas in other executions.

## Usage

Create `.env` file with the following content:

```text
# RPC
INFURA_API_KEY="YOUR-INFURA_API_KEY"
RPC_ETHEREUM="https://mainnet.infura.io/v3/${INFURA_API_KEY}"

# BlockExplorer
ETHERSCAN_API_KEY_ETHEREUM="YOUR-ETHERSCAN_API_KEY_ETHEREUM"
ETHERSCAN_URL_ETHEREUM="https://api.etherscan.io/api"

# Optional
FORK_BLOCK_ETHEREUM=20313600
```

**The test environment will be forked at the latest block if `FORK_BLOCK_ETHEREUM` is not defined.**

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
