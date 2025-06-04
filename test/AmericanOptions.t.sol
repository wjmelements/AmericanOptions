// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AmericanCallOptions} from "../src/AmericanOptions.sol";
import {TestUSD} from "./TestUSD.sol";
import {MarketId} from "../src/MarketId.sol";

contract AmericanOptionsTest is Test {
    AmericanCallOptions public options;
    TestUSD base;
    TestUSD token;

    uint256 constant DAY = 24 * 60 * 60;

    function setUp() public {
        base = new TestUSD();
        token = new TestUSD();
        base.mint(10000_00);
        token.mint(10000_00);

        options = new AmericanCallOptions(base);
    }

    function test_DepositWithraw() public {
        vm.expectRevert();
        options.depositTo(address(this), base, 1_00);

        base.approve(address(options), 1_00);
        options.depositTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 9999_00);
        assertEq(base.balanceOf(address(options)), 1_00);
        assertEq(options.balanceOf(address(this), MarketId.fromToken(base)), 1_00);

        options.withdrawTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 10000_00);
    }

    function testFuzz_SetOperatorTransferFrom(address spender, address recipient) public {
        assertTrue(options.setOperator(spender, true));
        assertTrue(options.isOperator(address(this), spender));

        base.approve(address(options), 1_00);
        options.depositTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 9999_00);
        assertEq(base.balanceOf(address(options)), 1_00);
        assertEq(options.balanceOf(address(this), MarketId.fromToken(base)), 1_00);

        vm.prank(recipient);
        vm.expectRevert();
        options.transferFrom(address(this), recipient, MarketId.fromToken(base), 1_00);

        vm.prank(spender);
        options.transferFrom(address(this), recipient, MarketId.fromToken(base), 1_00);
        assertEq(options.balanceOf(recipient, MarketId.fromToken(base)), 1_00);

        vm.prank(recipient);
        options.withdrawTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 10000_00);
    }

    function testFuzz_ApproveTransferFrom(address spender, address recipient) public {
        assertTrue(options.approve(spender, MarketId.fromToken(base), 1_00));
        assertEq(options.allowance(address(this), spender, MarketId.fromToken(base)), 1_00);

        base.approve(address(options), 1_00);
        options.depositTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 9999_00);
        assertEq(base.balanceOf(address(options)), 1_00);
        assertEq(options.balanceOf(address(this), MarketId.fromToken(base)), 1_00);

        vm.prank(recipient);
        vm.expectRevert();
        options.transferFrom(address(this), recipient, MarketId.fromToken(base), 1_00);

        vm.prank(spender);
        options.transferFrom(address(this), recipient, MarketId.fromToken(base), 1_00);
        assertEq(options.balanceOf(recipient, MarketId.fromToken(base)), 1_00);
        assertEq(options.allowance(address(this), spender, MarketId.fromToken(base)), 0);

        vm.prank(recipient);
        options.withdrawTo(address(this), base, 1_00);
        assertEq(base.balanceOf(address(this)), 10000_00);
    }

    function test_DepositOpenCloseWithdraw() public {
        token.approve(address(options), 1_00);
        options.depositTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 9999_00);
        assertEq(token.balanceOf(address(options)), 1_00);

        {
            uint256 expiry = block.timestamp + 2 * DAY;
            uint256 strike = 48592008000;
            uint256 marketId = MarketId.pack(token, expiry, strike);
            options.open(marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 1_00);

            options.close(marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 0);
        }

        options.withdrawTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 10000_00);
    }

    function test_DepositOpenExpireWithdraw() public {
        token.approve(address(options), 1_00);
        options.depositTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 9999_00);
        assertEq(token.balanceOf(address(options)), 1_00);

        {
            uint256 expiry = block.timestamp + 2 * DAY;
            uint256 strike = 48592008000;
            uint256 marketId = MarketId.pack(token, expiry, strike);
            options.open(marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 1_00);

            options.transfer(address(0), marketId, 1_00);
            assertEq(options.balanceOf(address(this), marketId), 0);

            vm.expectRevert();
            options.expire(marketId, 1_00);

            skip(2 * DAY);

            options.expire(marketId, 1_00);

            vm.expectRevert();
            options.expire(marketId, 1_00);
        }

        options.withdrawTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 10000_00);
    }

    function testFuzz_OpenExerciseAcceptAssignment(address counterparty, address recipient) public {
        token.approve(address(options), 1_00);
        options.depositTo(address(this), token, 1_00);
        assertEq(token.balanceOf(address(this)), 9999_00);
        assertEq(token.balanceOf(address(options)), 1_00);
        assertEq(options.balanceOf(address(this), MarketId.fromToken(token)), 1_00);

        base.transfer(counterparty, 4_00);
        assertEq(base.balanceOf(counterparty), 4_00);
        assertEq(base.balanceOf(address(this)), 9996_00);

        uint256 strike = 1 << 37; // 4
        uint256 marketId = MarketId.pack(token, block.timestamp + DAY, strike);
        options.open(marketId, 100);
        assertEq(options.balanceOf(address(this), marketId), 1_00);
        assertEq(options.balanceOf(address(this), MarketId.fromToken(token)), 0);

        options.transfer(counterparty, marketId, 1_00);
        assertEq(options.balanceOf(address(this), marketId), 0);
        assertEq(options.balanceOf(counterparty, marketId), 1_00);

        vm.startPrank(counterparty);
        {
            base.approve(address(options), 4_00);
            options.depositTo(counterparty, base, 4_00);
            assertEq(options.balanceOf(counterparty, MarketId.fromToken(base)), 4_00);

            options.exercise(marketId, 1_00);
            assertEq(options.balanceOf(counterparty, MarketId.fromToken(base)), 0);
            assertEq(options.balanceOf(counterparty, MarketId.fromToken(token)), 1_00);

            options.withdrawTo(recipient, token, 1_00);
            assertEq(token.balanceOf(recipient), 1_00);
        }
        vm.stopPrank();

        skip(DAY);
        vm.expectRevert();
        options.expire(marketId, 1_00);

        options.acceptAssignment(marketId, 1_00);
        assertEq(options.balanceOf(address(this), MarketId.fromToken(base)), 4_00);

        options.withdrawTo(recipient, base, 4_00);
        assertEq(base.balanceOf(recipient), 4_00);
    }
}
