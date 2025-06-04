// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {MarketId} from "../src/MarketId.sol";
import {Expiry} from "../src/Expiry.sol";
import {TestUSD} from "./TestUSD.sol";

contract AmericanOptionsTest is Test {
    TestUSD usd;

    using MarketId for uint256;
    using Expiry for uint256;

    function setUp() public {
        usd = new TestUSD();
    }

    function test_USD_pack_unpack() public view {
        uint256 expiry = block.timestamp.toExpiry();
        assertTrue(expiry.isValidExpiry());
        uint256 strike = 3_00;
        uint256 marketId = MarketId.pack(usd, expiry, strike);
        (IERC20 tokenDecoded, uint256 expiryDecoded, uint256 strikeDecoded) = marketId.unpack();
        assertEq(address(tokenDecoded), address(usd));
        assertEq(strikeDecoded, strike);
        assertEq(expiryDecoded, expiry);

        assertEq(address(marketId.toToken()), address(usd));
        assertEq(address(MarketId.fromToken(usd).toToken()), address(usd));
        assertEq(MarketId.fromToken(usd).toTokenId(), MarketId.fromToken(usd));
    }

    function test_USD_unpack_pack() public pure {
        uint256 marketId = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        (IERC20 token, uint256 expiry, uint256 strike) = marketId.unpack();
        uint256 marketIdDecoded = MarketId.pack(token, expiry, strike);
        assertEq(marketIdDecoded, marketId);
    }
}
