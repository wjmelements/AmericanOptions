// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// 72-bit square root pricing with 1.0 as 2**40
library PriceQ40 {
    uint256 constant Q40_SQUARE_REMAINDER_MASK = 0xffffffffffffffffffff;

    function toBaseDown(uint256 price, uint256 tokenAmount) internal pure returns (uint256 baseAmount) {
        baseAmount = tokenAmount * price * price >> 80;
    }

    function toBaseUp(uint256 price, uint256 tokenAmount) internal pure returns (uint256 baseAmount) {
        baseAmount = tokenAmount * price * price;
        if ((baseAmount & Q40_SQUARE_REMAINDER_MASK) != 0) {
            return (baseAmount >> 80) + 1;
        } else {
            return baseAmount >> 80;
        }
    }
}
