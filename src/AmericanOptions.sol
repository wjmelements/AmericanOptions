// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MarketId} from "./MarketId.sol";

contract AmericanOptions {
    IERC20 private immutable base;

    using MarketId for uint256;

    constructor(IERC20 base_) {
        base = base_;
    }
}
