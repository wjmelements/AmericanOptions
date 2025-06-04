// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AmericanCallOptions} from "../src/AmericanOptions.sol";
import {TestUSD} from "./TestUSD.sol";
import {MarketId} from "../src/MarketId.sol";

contract AmericanOptionsTest is Test {
    AmericanCallOptions public options;
    TestUSD base;
    TestUSD token;

    uint256 constant DAY = 24 * 60 * 60;

    function setUp() public {
        base = new TestUSD();
        token = new TestUSD();
        base.mint(10000_00);
        token.mint(10000_00);

        options = new AmericanCallOptions(base);
    }

    function test_DepositWithraw() public {
        base.approve(address(options), 1_00);
        options.depositTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 9999_00);
        assertEq(base.balanceOf(address(options)), 1_00);
        assertEq(options.balanceOf(address(this), MarketId.fromToken(base)), 1_00);

        options.withdrawTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 10000_00);
    }

    function test_DepositOpenCloseWithdraw() public {
        token.approve(address(options), 1_00);
        options.depositTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 9999_00);
        assertEq(token.balanceOf(address(options)), 1_00);

        {
            uint expiry = block.timestamp + 2 * DAY;
            uint strike = 48592008000;
            uint marketId = MarketId.pack(token, expiry, strike);
            options.open(marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 1_00);

            options.close(marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 0);
        }

        options.withdrawTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 10000_00);
    }

    function test_DepositOpenExpireWithdraw() public {
        token.approve(address(options), 1_00);
        options.depositTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 9999_00);
        assertEq(token.balanceOf(address(options)), 1_00);

        {
            uint expiry = block.timestamp + 2 * DAY;
            uint strike = 48592008000;
            uint marketId = MarketId.pack(token, expiry, strike);
            options.open(marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 1_00);

            options.transfer(address(0), marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 0);

            skip(2 * DAY);

            options.expire(marketId, 1_00);
        }

        options.withdrawTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 10000_00);
    }
}
