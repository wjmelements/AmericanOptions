// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC6909} from "forge-std/interfaces/IERC6909.sol";
import {MarketId} from "./MarketId.sol";
import {PriceQ40} from "./PriceQ40.sol";

contract AmericanCallOptions is IERC6909 {
    IERC20 public immutable baseToken;
    uint256 private immutable baseMarket;

    constructor(IERC20 _base) {
        baseToken = _base;
        baseMarket = MarketId.fromToken(_base);
    }

    using MarketId for uint256;
    using PriceQ40 for uint256;

    /// @inheritdoc IERC6909
    mapping(address account => mapping(uint256 marketId => uint256)) public balanceOf;
    /// @inheritdoc IERC6909
    mapping(address owner => mapping(address spender => mapping(uint256 marketId => uint256))) public allowance;
    /// @inheritdoc IERC6909
    mapping(address owner => mapping(address spender => bool)) public isOperator;

    /// @notice Deposit tokens into the protocol
    /// @param recipient who to credit
    /// @param token the token to deposit
    /// @param amount how many tokens
    function depositTo(address recipient, IERC20 token, uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount));
        balanceOf[recipient][MarketId.fromToken(token)] += amount;
        emit Transfer(msg.sender, address(0), recipient, MarketId.fromToken(token), amount);
    }

    /// @notice Withdraw tokens from the protocol
    /// @param recipient who receives the tokens
    /// @param token the token to withdraw
    /// @param amount how many tokens
    function withdrawTo(address recipient, IERC20 token, uint256 amount) external {
        require(token.transfer(recipient, amount));
        balanceOf[msg.sender][MarketId.fromToken(token)] -= amount;
        emit Transfer(msg.sender, recipient, address(0), MarketId.fromToken(token), amount);
    }

    /// @inheritdoc IERC6909
    function transfer(address recipient, uint256 id, uint256 amount) external returns (bool) {
        balanceOf[msg.sender][id] -= amount;
        balanceOf[recipient][id] += amount;
        emit Transfer(msg.sender, msg.sender, recipient, id, amount);
        return true;
    }

    /// @inheritdoc IERC6909
    function transferFrom(address owner, address recipient, uint256 id, uint256 amount) external returns (bool) {
        if (!isOperator[owner][msg.sender]) {
            allowance[owner][msg.sender][id] -= amount;
        }
        balanceOf[owner][id] -= amount;
        balanceOf[recipient][id] += amount;
        emit Transfer(msg.sender, owner, recipient, id, amount);
        return true;
    }

    /// @inheritdoc IERC6909
    function setOperator(address spender, bool approved) external returns (bool) {
        isOperator[msg.sender][spender] = approved;
        emit OperatorSet(msg.sender, spender, approved);
        return true;
    }

    /// @inheritdoc IERC6909
    function approve(address spender, uint256 id, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public pure returns (bool supported) {
        return interfaceId == 0x0f632fb3 || interfaceId == 0x01ffc9a7;
    }

    // Markets
    struct Market {
        uint128 remaining;
        uint128 exercised;
    }

    mapping(address owner => mapping(uint256 marketId => uint128)) public lockedCollateral;
    mapping(uint256 marketId => Market) public markets;

    /// @notice Lock tokens to write call options
    /// @param marketId specifying the call's token, expiration, and strike price
    /// @param amount tokens to write options against
    function open(uint256 marketId, uint128 amount) external {
        (IERC20 token, uint256 expiry, /*uint256 strike*/ ) = marketId.unpack();
        require(expiry >= block.timestamp);
        balanceOf[msg.sender][MarketId.fromToken(token)] -= amount;
        emit Transfer(msg.sender, msg.sender, address(0), MarketId.fromToken(token), amount);
        lockedCollateral[msg.sender][marketId] += amount;
        balanceOf[msg.sender][marketId] += amount;
        emit Transfer(msg.sender, address(0), msg.sender, marketId, amount);
        markets[marketId].remaining += amount;
    }

    /// @notice Exercise call options, purchasing locked tokens at the strike price
    /// @param marketId specifying the call's token, expiration, and strike price
    /// @param amount tokens to purchase
    function exercise(uint256 marketId, uint128 amount) external {
        (IERC20 token, uint256 expiry, uint256 strike) = marketId.unpack();
        require(expiry >= block.timestamp);
        uint256 baseAmount = strike.toBaseUp(amount);
        balanceOf[msg.sender][baseMarket] -= baseAmount;
        emit Transfer(msg.sender, msg.sender, address(0), baseMarket, baseAmount);
        balanceOf[msg.sender][marketId] -= amount;
        emit Transfer(msg.sender, msg.sender, address(0), marketId, amount);
        balanceOf[msg.sender][MarketId.fromToken(token)] += amount;
        emit Transfer(msg.sender, address(0), msg.sender, MarketId.fromToken(token), amount);
        markets[marketId].exercised += amount;
        markets[marketId].remaining -= amount;
    }

    /// @notice Burn call options to release locked collateral
    /// @param marketId specifying the call's token, expiration, and strike price
    /// @param amount tokens to release
    function close(uint256 marketId, uint128 amount) external {
        markets[marketId].remaining -= amount;
        balanceOf[msg.sender][marketId] -= amount;
        emit Transfer(msg.sender, msg.sender, address(0), marketId, amount);
        balanceOf[msg.sender][marketId.toTokenId()] += amount;
        emit Transfer(msg.sender, address(0), msg.sender, marketId.toTokenId(), amount);
        lockedCollateral[msg.sender][marketId] -= amount;
    }

    /// @notice Release locked collateral backing expired call options
    /// @param marketId specifying the call's token, expiration, and strike price
    /// @param amount tokens to release
    function expire(uint256 marketId, uint128 amount) external {
        (IERC20 token, uint256 expiry, /*uint256 strike*/ ) = marketId.unpack();
        require(expiry < block.timestamp);
        lockedCollateral[msg.sender][marketId] -= amount;
        markets[marketId].remaining -= amount;
        balanceOf[msg.sender][MarketId.fromToken(token)] += amount;
        emit Transfer(msg.sender, address(0), msg.sender, MarketId.fromToken(token), amount);
    }

    /// @notice Convert locked collateral into base tokens at the strike price
    /// @param marketId specifying the call's token, expiration, and strike price
    /// @param amount locked collateral to release
    function acceptAssignment(uint256 marketId, uint128 amount) external {
        ( /*IERC20 token*/ , /*uint256 expiry*/, uint256 strike) = marketId.unpack();
        markets[marketId].exercised -= amount;
        uint256 baseAmount = strike.toBaseDown(amount);
        balanceOf[msg.sender][baseMarket] += baseAmount;
        emit Transfer(msg.sender, address(0), msg.sender, baseMarket, baseAmount);
        lockedCollateral[msg.sender][marketId] -= amount;
    }
}
