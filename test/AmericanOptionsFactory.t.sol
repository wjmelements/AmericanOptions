// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {AmericanCallOptions} from "../src/AmericanOptions.sol";
import {AmericanCallOptionsFactory} from "../src/AmericanOptionsFactory.sol";
import {TestUSD} from "./TestUSD.sol";

contract AmericanOptionsFactoryTest is Test {
    AmericanCallOptionsFactory factory;
    TestUSD baseToken;
    TestUSD otherToken;

    function setUp() public {
        baseToken = new TestUSD();
        otherToken = new TestUSD();
        factory = new AmericanCallOptionsFactory();
    }

    function test_deploy() public {
        AmericanCallOptions optionsMarkets = factory.createOptionsMarkets(baseToken);
        bytes32 initCodeHash = keccak256(bytes.concat(type(AmericanCallOptions).creationCode, abi.encode(baseToken)));
        bytes32 salt = bytes32(0);
        assertEq(
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(factory), salt, initCodeHash))))),
            address(optionsMarkets)
        );
    }

    function test_deployOther() public {
        AmericanCallOptions baseOptionsMarkets = factory.createOptionsMarkets(baseToken);
        AmericanCallOptions otherOptionsMarkets = factory.createOptionsMarkets(otherToken);
        assertTrue(baseOptionsMarkets != AmericanCallOptions(address(0)));
        assertTrue(otherOptionsMarkets != AmericanCallOptions(address(0)));
        assertTrue(baseOptionsMarkets != otherOptionsMarkets);
    }

    function test_deployTwice() public {
        AmericanCallOptions markets1 = factory.createOptionsMarkets(baseToken);
        AmericanCallOptions markets2 = factory.createOptionsMarkets(baseToken);
        assertEq(address(markets1), address(markets2));
    }
}
