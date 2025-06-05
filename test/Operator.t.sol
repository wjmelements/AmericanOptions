// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AmericanCallOptions} from "../src/AmericanOptions.sol";
import {MarketId} from "../src/MarketId.sol";
import {AmericanOptions7702Operator} from "../src/Operator.sol";
import {TestUSD} from "./TestUSD.sol";

contract AmericanOptions7702OperatorTest is Test {
    TestUSD base;
    TestUSD token;
    AmericanCallOptions options;
    AmericanOptions7702Operator operator;
    address alice;
    uint256 aliceKey;
    AmericanOptions7702Operator operatorAlice;

    using MarketId for uint256;

    uint256 constant DAY = 24 * 60 * 60;

    function setUp() public {
        base = new TestUSD();
        token = new TestUSD();
        base.mint(5000000_00);
        token.mint(500000_00);

        options = new AmericanCallOptions(base);
        operator = new AmericanOptions7702Operator(options);

        (alice, aliceKey) = makeAddrAndKey("alice");
        // eip 7702: set delegate to operator
        vm.signAndAttachDelegation(address(operator), aliceKey);
        token.transfer(alice, 1000_00);
        operatorAlice = AmericanOptions7702Operator(alice);
    }

    function test_PreventsPublicUse() public {
        uint256 expiry = block.timestamp + 7 * DAY;
        uint256 strike = 1 << 39; // 1/4
        uint256 marketId = MarketId.pack(token, expiry, strike);

        vm.expectRevert();
        operatorAlice.depositAllAndOpen(marketId);

        vm.expectRevert();
        operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);

        vm.expectRevert();
        operatorAlice.exerciseAll(marketId);

        vm.expectRevert();
        operatorAlice.reverseExercise(marketId, 0);

        vm.expectRevert();
        operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);

        vm.expectRevert();
        operatorAlice.closePosition(marketId, 0, 0);
    }

    function testFuzz_ClosePosition_NoneExercised(bool preferCollateral) public {
        assertEq(token.balanceOf(alice), 1000_00);
        vm.startPrank(alice);
        {
            uint256 expiry = block.timestamp + 7 * DAY;
            uint256 strike = 1 << 39; // 1/4
            uint256 marketId = MarketId.pack(token, expiry, strike);

            operatorAlice.depositAllAndOpen(marketId);
            assertEq(token.balanceOf(alice), 0);
            assertEq(token.balanceOf(address(options)), 1000_00);

            vm.expectRevert();
            if (preferCollateral) {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            } else {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringAssignment(marketId);
            }

            skip(7 * DAY);
            if (preferCollateral) {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            } else {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringAssignment(marketId);
            }
            assertEq(token.balanceOf(alice), 1000_00);
        }
        vm.stopPrank();
    }

    function testFuzz_ClosePosition_AllExercised(address purchaser, bool preferCollateral) public {
        assertEq(token.balanceOf(alice), 1000_00);

        uint256 expiry = block.timestamp + 7 * DAY;
        uint256 strike = 1 << 39; // 1/4
        uint256 marketId = MarketId.pack(token, expiry, strike);

        vm.startPrank(alice);
        {
            operatorAlice.depositAllAndOpen(marketId);
            assertEq(token.balanceOf(alice), 0);
            assertEq(token.balanceOf(address(options)), 1000_00);
            assertEq(options.balanceOf(alice, marketId), 1000_00);

            vm.expectRevert();
            if (preferCollateral) {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            } else {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringAssignment(marketId);
            }

            options.transfer(purchaser, marketId, 1000_00);
            if (alice != purchaser) {
                assertEq(options.balanceOf(purchaser, marketId), 1000_00);
                assertEq(options.balanceOf(alice, marketId), 0);
            } else {
                assertEq(options.balanceOf(purchaser, marketId), 1000_00);
            }
        }
        vm.stopPrank();

        (uint128 remaining, uint128 exercised) = options.markets(marketId);
        assertEq(remaining, 1000_00);
        assertEq(exercised, 0);

        base.transfer(purchaser, 250_00);
        vm.startPrank(purchaser);
        {
            base.approve(address(options), 250_00);
            options.depositTo(purchaser, base, 250_00);

            options.exercise(marketId, 1000_00);
            assertEq(options.balanceOf(purchaser, marketId), 0);
            assertEq(options.balanceOf(purchaser, MarketId.fromToken(base)), 0);
            (remaining, exercised) = options.markets(marketId);
            assertEq(remaining, 0);
            assertEq(exercised, 1000_00);
        }
        vm.stopPrank();

        vm.startPrank(alice);
        {
            skip(7 * DAY);
            if (preferCollateral) {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            } else {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringAssignment(marketId);
            }
            assertEq(base.balanceOf(alice), 250_00);
        }
    }

    function testFuzz_ClosePosition_HalfExercised(address purchaser, bool preferCollateral) public {
        assertEq(token.balanceOf(alice), 1000_00);

        uint256 expiry = block.timestamp + 7 * DAY;
        uint256 strike = 1 << 39; // 1/4
        uint256 marketId = MarketId.pack(token, expiry, strike);

        vm.startPrank(alice);
        {
            operatorAlice.depositAllAndOpen(marketId);
            assertEq(token.balanceOf(alice), 0);
            assertEq(token.balanceOf(address(options)), 1000_00);
            assertEq(options.balanceOf(alice, marketId), 1000_00);

            vm.expectRevert();
            if (preferCollateral) {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            } else {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringAssignment(marketId);
            }

            options.transfer(purchaser, marketId, 1000_00);
            if (purchaser != alice) {
                assertEq(options.balanceOf(purchaser, marketId), 1000_00);
                assertEq(options.balanceOf(alice, marketId), 0);
            } else {
                assertEq(options.balanceOf(alice, marketId), 1000_00);
            }
        }
        vm.stopPrank();

        (uint128 remaining, uint128 exercised) = options.markets(marketId);
        assertEq(remaining, 1000_00);
        assertEq(exercised, 0);

        base.transfer(purchaser, 125_00);
        vm.startPrank(purchaser);
        {
            base.approve(address(options), 125_00);
            options.depositTo(purchaser, base, 125_00);

            options.exercise(marketId, 500_00);
            assertEq(options.balanceOf(purchaser, marketId), 500_00);
            assertEq(options.balanceOf(purchaser, MarketId.fromToken(base)), 0);
            (remaining, exercised) = options.markets(marketId);
            assertEq(remaining, 500_00);
            assertEq(exercised, 500_00);
        }
        vm.stopPrank();

        vm.startPrank(alice);
        {
            skip(7 * DAY);
            if (preferCollateral) {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            } else {
                operatorAlice.closeAndWithdrawExpiredPositionPreferringAssignment(marketId);
            }
            assertEq(base.balanceOf(alice), 125_00);
            assertEq(token.balanceOf(alice), 500_00);
        }
    }

    function test_exerciseAll() public {
        base.transfer(alice, 4100000_00);

        uint256 expiry = block.timestamp + 1 * DAY;
        uint256 strike = 1 << 46; // 4096
        uint256 marketId = MarketId.pack(token, expiry, strike);

        vm.startPrank(alice);
        {
            operatorAlice.depositAllAndOpen(marketId);
            assertEq(token.balanceOf(alice), 0);
            assertEq(options.balanceOf(alice, marketId), 1000_00);

            operatorAlice.exerciseAll(marketId);
            assertEq(options.balanceOf(alice, marketId), 0);
            assertEq(token.balanceOf(alice), 1000_00);
            assertEq(base.balanceOf(alice), 4000_00);

            operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            assertEq(token.balanceOf(alice), 1000_00);
            assertEq(base.balanceOf(alice), 4100000_00);
        }
        vm.stopPrank();
    }

    function test_reverseExercise() public {
        base.transfer(alice, 9000_00);

        uint256 expiry = block.timestamp + 1 * DAY;
        uint256 strike = 3 << 40; // 9
        uint256 marketId = MarketId.pack(token, expiry, strike);

        (uint128 remaining, uint128 exercised) = options.markets(marketId);
        assertEq(remaining, 0);
        assertEq(exercised, 0);

        vm.startPrank(alice);
        {
            operatorAlice.depositAllAndOpen(marketId);
            assertEq(token.balanceOf(alice), 0);
            assertEq(options.balanceOf(alice, marketId), 1000_00);
            (remaining, exercised) = options.markets(marketId);
            assertEq(remaining, 1000_00);
            assertEq(exercised, 0);

            operatorAlice.exerciseAll(marketId);
            assertEq(options.balanceOf(alice, marketId), 0);
            assertEq(token.balanceOf(alice), 1000_00);
            assertEq(base.balanceOf(alice), 0);
            (remaining, exercised) = options.markets(marketId);
            assertEq(remaining, 0);
            assertEq(exercised, 1000_00);

            operatorAlice.reverseExercise(marketId, 1000_00);
            assertEq(options.balanceOf(alice, marketId), 1000_00);
            assertEq(token.balanceOf(alice), 0);
            assertEq(base.balanceOf(alice), 9000_00);
            (remaining, exercised) = options.markets(marketId);
            assertEq(remaining, 1000_00);
            assertEq(exercised, 0);

            operatorAlice.exerciseAll(marketId);
            assertEq(options.balanceOf(alice, marketId), 0);
            assertEq(token.balanceOf(alice), 1000_00);
            assertEq(base.balanceOf(alice), 0);
            (remaining, exercised) = options.markets(marketId);
            assertEq(remaining, 0);
            assertEq(exercised, 1000_00);

            operatorAlice.closeAndWithdrawExpiredPositionPreferringCollateral(marketId);
            assertEq(token.balanceOf(alice), 1000_00);
            assertEq(base.balanceOf(alice), 9000_00);
            (remaining, exercised) = options.markets(marketId);
            assertEq(remaining, 0);
            assertEq(exercised, 0);
        }
        vm.stopPrank();
    }
}
