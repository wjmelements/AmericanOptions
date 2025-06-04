pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PriceQ40} from "../src/PriceQ40.sol";

contract PriceQ40Test is Test {
    using PriceQ40 for uint256;

    function test_toBase() public pure {
        uint256 ONE = 1 << 40;
        uint256 ONE_QUARTER = 1 << 39;
        uint256 FOUR = 1 << 41;
        uint256 WAD = ONE * 10 ** 9;
        uint256 UNWAD = ONE / 10 ** 9;

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

        assertEq(WAD.toBaseUp(100), 100 * 10 ** 18);
        assertEq(WAD.toBaseDown(100), 100 * 10 ** 18);

        assertEq(UNWAD.toBaseUp(100 * 10 ** 18), 100);
        assertEq(UNWAD.toBaseDown(100 * 10 ** 18), 99);
    }
}
