pragma solidity ^0.8.13;

library Expiry {
    uint256 private constant EXPIRY_MASK = 0xffffff0000;

    function toExpiry(uint256 timestamp) internal pure returns (uint256 expiry) {
        expiry = timestamp & EXPIRY_MASK;
    }

    function isValidExpiry(uint256 timestamp) internal pure returns (bool valid) {
        valid = timestamp <= EXPIRY_MASK && toExpiry(timestamp) == timestamp;
    }
}
