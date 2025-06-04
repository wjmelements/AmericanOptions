pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

library MarketId {
    uint256 private constant KEY_EXPIRY_MASK = 0x000000000000000000ffffff0000000000000000000000000000000000000000;
    // expiry: lower 2 bytes are zero

    function unpack(uint256 key) internal pure returns (IERC20 token, uint256 expiry, uint256 strike) {
        token = IERC20(address(uint160(key)));
        expiry = (key & KEY_EXPIRY_MASK) >> 144;
        strike = key >> 184;
    }

    function pack(IERC20 token, uint256 expiry, uint256 strike) internal pure returns (uint256 key) {
        key = uint256(uint160(address(token))) | (expiry >> 16) << 160 | strike << 184;
    }
}
