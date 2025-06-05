// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AmericanCallOptions} from "./AmericanOptions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MarketId} from "./MarketId.sol";
import {PriceQ40} from "./PriceQ40.sol";

contract AmericanOptions7702Operator {
    AmericanCallOptions private immutable options;
    IERC20 private immutable baseToken;

    using MarketId for uint256;
    using PriceQ40 for uint256;

    constructor(AmericanCallOptions _options) {
        options = _options;
        baseToken = _options.baseToken();
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    function depositAllAndOpen(uint256 marketId) external onlySelf {
        IERC20 token = marketId.toToken();
        uint256 balance = token.balanceOf(msg.sender);
        token.approve(address(options), balance);
        options.depositTo(msg.sender, token, balance);
        options.open(marketId, uint128(balance));
    }

    function closeAndWithdrawExpiredPositionPreferringCollateral(uint256 marketId) external onlySelf {
        uint128 locked = options.lockedCollateral(msg.sender, marketId);
        (uint128 remaining, uint128 exercised) = options.markets(marketId);
        if (remaining > 0) {
            if (remaining >= locked) {
                exercised = 0;
                remaining = locked;
            } else {
                exercised = locked - remaining;
            }
        } else {
            exercised = locked;
        }
        if (remaining > 0) {
            options.expire(marketId, remaining);
            options.withdrawTo(msg.sender, marketId.toToken(), remaining);
        }
        if (exercised > 0) {
            options.acceptAssignment(marketId, exercised);
            ( /*IERC20 token*/ , /*uint256 expiry*/, uint256 strike) = marketId.unpack();
            options.withdrawTo(msg.sender, baseToken, strike.toBaseDown(exercised));
        }
    }
}
