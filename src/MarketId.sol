// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

library MarketId {
    uint256 private constant KEY_TOKEN_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant KEY_EXPIRY_MASK = 0x000000000000000000ffffff0000000000000000000000000000000000000000;
    uint256 private constant KEY_PRICE_MASK = 0xffffffffffffffffff0000000000000000000000000000000000000000000000;
    // expiry: lower 2 bytes are zero

    function unpack(uint256 key) internal pure returns (IERC20 token, uint256 expiry, uint256 strike) {
        token = IERC20(address(uint160(key)));
        expiry = (key & KEY_EXPIRY_MASK) >> 144;
        strike = key >> 184;
    }

    function pack(IERC20 token, uint256 expiry, uint256 strike) internal pure returns (uint256 key) {
        key = uint256(uint160(address(token))) | (expiry >> 16) << 160 | strike << 184;
    }

    function toStrike(uint256 key) internal pure returns (uint256 strike) {
        return key >> 184;
    }

    function fromToken(IERC20 token) internal pure returns (uint256 key) {
        key = uint256(uint160(address(token)));
    }

    function toToken(uint256 key) internal pure returns (IERC20 token) {
        token = IERC20(address(uint160(key)));
    }

    function toTokenId(uint256 key) internal pure returns (uint256 tokenKey) {
        tokenKey = key & KEY_TOKEN_MASK;
    }
}
