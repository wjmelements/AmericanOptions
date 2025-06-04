// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// 72-bit square root pricing with 1.0 as 2**36
library PriceQ36 {
    uint256 constant Q36_SQUARE_REMAINDER_MASK = 0xffffffffffffffffff;

    function toBaseDown(uint256 price, uint256 tokenAmount) internal pure returns (uint256 baseAmount) {
        baseAmount = tokenAmount * price * price >> 72;
    }

    function toBaseUp(uint256 price, uint256 tokenAmount) internal pure returns (uint256 baseAmount) {
        baseAmount = tokenAmount * price * price;
        if ((baseAmount & Q36_SQUARE_REMAINDER_MASK) != 0) {
            return (baseAmount >> 72) + 1;
        } else {
            return baseAmount >> 72;
        }
    }
}
