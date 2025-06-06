// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AmericanCallOptions} from "./AmericanOptions.sol";

contract AmericanCallOptionsFactory {
    mapping(IERC20 baseToken => AmericanCallOptions) public optionsMarkets;

    event NewOptionsMarkets(IERC20 indexed baseToken, AmericanCallOptions markets);

    function createOptionsMarkets(IERC20 baseToken) external returns (AmericanCallOptions markets) {
        markets = optionsMarkets[baseToken];
        if (markets != AmericanCallOptions(address(0))) {
            return markets;
        }
        markets = optionsMarkets[baseToken] =
            new AmericanCallOptions{salt: bytes32(uint256(uint160(address(baseToken))))}(baseToken);
        emit NewOptionsMarkets(baseToken, markets);
    }
}
