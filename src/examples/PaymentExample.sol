// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PaymentExample {
    address public lastSender;

    uint256 public lastValue;

    uint256 public totalReceived;

    event Paid(address indexed from, uint256 amount);

    function pay() external payable {
        require(msg.value > 0, "PaymentExample: zero payment");
        _record(msg.sender, msg.value);
    }

    receive() external payable {
        _record(msg.sender, msg.value);
    }

    function _record(address sender, uint256 amount) private {
        lastSender = sender;
        lastValue = amount;
        totalReceived += amount;
        emit Paid(sender, amount);
    }
}
