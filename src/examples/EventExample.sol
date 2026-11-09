// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EventExample {
    event Deposit(address indexed from, uint256 amount);

    uint256 public totalDeposited;

    function deposit() external payable {
        require(msg.value > 0, "EventExample: zero deposit");
        totalDeposited += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
