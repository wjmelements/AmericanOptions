// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {AmericanCallOptions} from "../src/AmericanOptions.sol";
import {AmericanCallOptionsFactory} from "../src/AmericanOptionsFactory.sol";
import {TestUSD} from "./TestUSD.sol";

contract AmericanOptionsFactoryTest is Test {
    AmericanCallOptionsFactory factory;
    TestUSD baseToken;

    function setUp() public {
        baseToken = new TestUSD();
        factory = new AmericanCallOptionsFactory();
    }

    function test_deploy() public {
        factory.createOptionsMarkets(baseToken);
    }

    function test_deployTwice() public {
        AmericanCallOptions markets1 = factory.createOptionsMarkets(baseToken);
        AmericanCallOptions markets2 = factory.createOptionsMarkets(baseToken);
        assertEq(address(markets1), address(markets2));
    }
}
