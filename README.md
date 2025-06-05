## AmericanCallOptions

This implements [American-Style](https://en.wikipedia.org/wiki/Option_style) Call Options as IERC6909.

### Operations
* **open**: lock your collateral and mint call options
* **exercise**: purchase collateral with call options and base tokens
* **close**: burn call options, unlock your collateral 
* **expire**: free collateral for expired options
* **acceptAssignment**: receive base tokens for sold locked collateral

#### Invariant
```
Market.exercised + Market.remaining = sum(lockedCollateral)
```

All operations modify Market.exercised + Market.remaining by the same amount that they modify lockedCollateral:

* `open` increases `lockedCollateral` and `Market.remaining` by `amount`.
* `exercise` increases `Market.exercised` by the same amount that it decreases `Market.remaining`.
* `close` and `expire` decrease `lockedCollateral` and `Market.remaining` by `amount`.
* `acceptAssignment` decreases `lockedCollateral` and `Market.exercised` by `amount`.


### MarketId
The upper bits of the option market identifier indicate the price and the expiry.

* token: 160 bits
* timestamp: 24 bits
* price: 72 bits


When expiry and price are 0, that refers to the raw token balance, used as collateral to mint call options.
This is safe because a market with expiry of zero cannot be created with `open` due to the expiry check.
Therefore such a market cannot have positive `lockedCollateral` or `Market.remaining`.
Without `lockedCollateral`, a market cannot `close`, `expire`, or `acceptAssignment`.
Without `Market.remaining`, a market cannot `exercise`, `close`, or `expire`.

Locked collateral is not transferrable between markets because different markets have different effective valuations for the collateral.
Locked collateral could be transferred between accounts but I haven't implemented that.


### Timestamp
The bottom 16 bits of the expiry timestamp are shaved off.
This restricts precision to an amount slightly less than a day.
The benefits are increased price precision, longer lifetime, and less liquidity fragmentation.
The timestamps would start to fail in the 37th millennium.
Then we would need a new protocol.

### Price
Price is a 72-bit square root ratio in [q32.40](https://en.wikipedia.org/wiki/Q_(number_format)), which I abbreviate as Q40 in the codebase.
This means that `2**40` is 1, `2**41` is 4, and `2**39` is 0.25.

Because of this design, higher prices have more precision than lower prices.
Additionally, squaring the price reduces precision by about half.
The highest possible price is about `16 * 10**18`.
The are still about 5 bits of precision when the effective price ratio was around `10**-18`.

The advantage of this design is a wider range of possible prices than could be achieved with fixed-precision.


### Assignment
Executing call options purchases locked collateral.
Instead of assigning call options randomly, they are assigned by the preference of the collateral on closing and expiry, first-come-first-serve.

There are some flaws to this.

If a call was executed and then the value of the token decreases, an unrelated party can mint new calls and redeem them into the base token.
This has a net effect of a reverse call exercise.
See `Operator.reverseExercise`;

Another flaw is that the first to exit are favored over the last to exit, because they may have a choice between claiming the collateral and claiming the base token.

## Operator
The Operator is a sample 7702 delegation specialized for options trading that can perform several common batched operations.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
$ forge coverage
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```
