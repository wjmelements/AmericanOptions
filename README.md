## AmericanCallOptions

This implements Call Options as IERC6909.

### TokenID
The upper bits of the token ID indicate the price and the expiry.
When expiry and price are 0, that refers to the raw token balance, used as collateral to mint call options.
This is safe because:
* an expiry of zero cannot be exercised
* TODO explain other cases

### Assignment
Executing call options purchases locked collateral.
Instead of assigning call options randomly, they are assigned by the preference of the collateral on closing and expiry, first-come-first-serve.


### Operations
* **open**: lock your collateral and mint call options
* **exercise**: purchase collateral with call options and base tokens
* **close**: burn call options, unlock your collateral 
* **closeExercised**: burn call options, receive base tokens
* **expire**: free collateral for expired options
* **expireExercised**: receive base tokens for sold locked collateral 

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
