// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract TestUSD is IERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address immutable minter;

    constructor() {
        minter = msg.sender;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address owner, address to, uint256 amount) external returns (bool) {
        allowance[owner][msg.sender] -= amount;
        balanceOf[owner] -= amount;
        balanceOf[to] += amount;
        emit Transfer(owner, to, amount);
        return true;
    }

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    function mint(uint256 amount) external onlyMinter {
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
    }

    function decimals() public pure returns (uint8) {
        return 2;
    }

    function name() public pure returns (string memory) {
        return "Test United States Dollars";
    }

    function symbol() public pure returns (string memory) {
        return "TestUSD";
    }
}
