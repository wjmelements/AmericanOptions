// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AmericanOptions} from "../src/AmericanOptions.sol";
import {TestUSD} from "./TestUSD.sol";

contract AmericanOptionsTest is Test {
    AmericanOptions public options;

    function setUp() public {
        TestUSD usd = new TestUSD();
        usd.mint(10000_00);
        options = new AmericanOptions(usd);
    }

    function test_Increment() public {}

    function testFuzz_SetNumber(uint256 x) public {}
}
