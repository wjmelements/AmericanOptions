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
        AmericanCallOptions optionsMarkets = factory.createOptionsMarkets(baseToken);
        bytes32 initCodeHash = keccak256(bytes.concat(type(AmericanCallOptions).creationCode, abi.encode(baseToken)));
        bytes32 salt = bytes32(uint256(uint160(address(baseToken))));
        assertEq(
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(factory), salt, initCodeHash))))),
            address(optionsMarkets)
        );
    }

    function test_deployTwice() public {
        AmericanCallOptions markets1 = factory.createOptionsMarkets(baseToken);
        AmericanCallOptions markets2 = factory.createOptionsMarkets(baseToken);
        assertEq(address(markets1), address(markets2));
    }
}
