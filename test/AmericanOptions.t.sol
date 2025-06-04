// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AmericanCallOptions} from "../src/AmericanOptions.sol";
import {TestUSD} from "./TestUSD.sol";

contract AmericanOptionsTest is Test {
    AmericanCallOptions public options;
    TestUSD base;
    TestUSD token;

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
        options.withdrawTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 10000_00);
    }
}
