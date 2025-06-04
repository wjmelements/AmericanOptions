## AmericanCallOptions

This implements Call Options as IERC6909.

### TokenID
The upper bits of the token ID indicate the price and the expiry.

When expiry and price are 0, that refers to the raw token balance, used as collateral to mint call options.
This is safe because:
* an expiry of zero cannot be exercised
* TODO explain other cases

Locked collateral is not transferrable between markets because different markets have different effective valuations for the collateral.

### Price
Price is a 72-bit square root ratio in q36.
This means that `2**36` is 1, `2**37` is 4, and `2**35` is 0.25.

### Assignment
Executing call options purchases locked collateral.
Instead of assigning call options randomly, they are assigned by the preference of the collateral on closing and expiry, first-come-first-serve.

There are some flaws to this.

If a call was executed and then the value of the token decreases, an unrelated party can mint new calls and redeem them into the base token.
This has the net effect of reversing a call execution.

Another flaw is that the first to exit are favored over the last to exit, because they may have a choice between claiming the collateral and claiming the base token.

### Operations
* **open**: lock your collateral and mint call options
* **exercise**: purchase collateral with call options and base tokens
* **close**: burn call options, unlock your collateral 
* **expire**: free collateral for expired options
* **acceptAssignment**: receive base tokens for sold locked collateral


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
