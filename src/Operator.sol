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

    /// @notice Lock all of your loose tokens into this market and write call options against them
    /// @param marketId specifying the call's token, expiration, and strike price
    function depositAllAndOpen(uint256 marketId) external onlySelf {
        IERC20 token = marketId.toToken();
        uint256 balance = token.balanceOf(msg.sender);
        token.approve(address(options), balance);
        options.depositTo(msg.sender, token, balance);
        options.open(marketId, uint128(balance));
    }

    /// @notice Exercise all of your calls, purchasing an equal amount of collateral at the strike price
    /// @param marketId specifying the call's token, expiration, and strike price
    function exerciseAll(uint256 marketId) external onlySelf {
        uint256 balance = options.balanceOf(msg.sender, marketId);
        uint256 cost = marketId.toStrike().toBaseUp(balance);
        baseToken.approve(address(options), cost);
        options.depositTo(msg.sender, baseToken, cost);
        options.exercise(marketId, uint128(balance));
        options.withdrawTo(msg.sender, marketId.toToken(), balance);
    }

    /// @notice Sell collateral at the strike price, also receiving an equal number of calls
    /// @param marketId specifying the call's token, expiration, and strike price
    /// @param maximum the maximum collateral amount to sell
    function reverseExercise(uint256 marketId, uint128 maximum) external onlySelf {
        ( /*uint128 remaining*/ , uint128 exercised) = options.markets(marketId);
        if (maximum < exercised) {
            exercised = maximum;
        }
        IERC20 token = marketId.toToken();
        token.approve(address(options), exercised);
        options.depositTo(msg.sender, token, exercised);
        options.open(marketId, exercised);
        options.acceptAssignment(marketId, exercised);
        options.withdrawTo(msg.sender, baseToken, marketId.toStrike().toBaseDown(exercised));
    }

    /// @notice Unlock all collateral as base tokens, receiving the rest as-is
    /// @param marketId specifying the call's token, expiration, and strike price
    function closePositionPreferringAssignment(uint256 marketId) external {
        // NOTE closePosition does the onlySelf check
        uint128 locked = options.lockedCollateral(msg.sender, marketId);
        (uint128 expired, uint128 exercised) = options.markets(marketId);
        if (exercised > 0) {
            if (exercised >= locked) {
                expired = 0;
                exercised = locked;
            } else {
                expired = locked - exercised;
            }
        } else {
            expired = locked;
        }
        closePosition(marketId, expired, exercised);
    }

    /// @notice Unlock all collateral as-is, receiving the rest as base tokens
    /// @param marketId specifying the call's token, expiration, and strike price
    function closePositionPreferringCollateral(uint256 marketId) external {
        // NOTE closePosition does the onlySelf check
        uint128 locked = options.lockedCollateral(msg.sender, marketId);
        (uint128 expired, uint128 exercised) = options.markets(marketId);
        if (expired > 0) {
            if (expired >= locked) {
                exercised = 0;
                expired = locked;
            } else {
                exercised = locked - expired;
            }
        } else {
            exercised = locked;
        }
        closePosition(marketId, expired, exercised);
    }

    /// @notice Unlock locked collateral
    /// @param marketId specifying the call's token, expiration, and strike price
    /// @param expired collateral amount to receive as collateral
    /// @param exercised collateral amount to accept as base tokens
    function closePosition(uint256 marketId, uint128 expired, uint128 exercised) public onlySelf {
        if (expired > 0) {
            options.expire(marketId, expired);
            options.withdrawTo(msg.sender, marketId.toToken(), expired);
        }
        if (exercised > 0) {
            options.acceptAssignment(marketId, exercised);
            options.withdrawTo(msg.sender, baseToken, marketId.toStrike().toBaseDown(exercised));
        }
    }
}
