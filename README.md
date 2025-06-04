## AmericanCallOptions

This implements Call Options as IERC6909.

### Operations
* **open**: lock your collateral and mint call options
* **exercise**: purchase collateral with call options and base tokens
* **close**: burn call options, unlock your collateral 
* **expire**: free collateral for expired options
* **acceptAssignment**: receive base tokens for sold locked collateral

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
The benefit is increased price precision and longer lifetime.
The timestamps would start to fail in the 37th millennium.
Then we would need a new protocol.

### Price
Price is a 72-bit square root ratio in [q32.40](https://en.wikipedia.org/wiki/Q_(number_format)), which I abbreviate as Q40 in the codebase.
This means that `2**40` is 1, `2**41` is 4, and `2**39` is 0.25.

### Assignment
Executing call options purchases locked collateral.
Instead of assigning call options randomly, they are assigned by the preference of the collateral on closing and expiry, first-come-first-serve.

There are some flaws to this.

If a call was executed and then the value of the token decreases, an unrelated party can mint new calls and redeem them into the base token.
This has the net effect of reversing a call exercise.

Another flaw is that the first to exit are favored over the last to exit, because they may have a choice between claiming the collateral and claiming the base token.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```
