pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PriceQ36} from "../src/PriceQ36.sol";

contract PriceQ36Test is Test {
    using PriceQ36 for uint256;

    function test_toBase() public pure {
        uint256 ONE = 1 << 36;
        uint256 ONE_QUARTER = 1 << 35;
        uint256 FOUR = 1 << 37;

        assertEq(ONE.toBaseUp(10 ** 27), 10 ** 27);
        assertEq(ONE.toBaseDown(10 ** 27), 10 ** 27);

        assertEq(ONE.toBaseUp(1), 1);
        assertEq(ONE.toBaseDown(1), 1);

        assertEq(FOUR.toBaseUp(1), 4);
        assertEq(FOUR.toBaseDown(1), 4);

        assertEq(ONE_QUARTER.toBaseUp(4), 1);
        assertEq(ONE_QUARTER.toBaseDown(4), 1);

        assertEq(ONE_QUARTER.toBaseUp(3), 1);
        assertEq(ONE_QUARTER.toBaseDown(3), 0);

        assertEq(ONE_QUARTER.toBaseUp(3 * 10 ** 18), 75 * 10 ** 16);
        assertEq(ONE_QUARTER.toBaseDown(3 * 10 ** 18), 75 * 10 ** 16);
    }
}
