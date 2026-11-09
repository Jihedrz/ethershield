// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract RefundPoolFixed {
    mapping(address => uint256) public contributions;

    event Contributed(address indexed contributor, uint256 amount);

    event Refunded(address indexed contributor, uint256 amount);

    function contribute() external payable {
        require(msg.value > 0, "RefundPoolFixed: zero contribution");
        contributions[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    function refund() external {
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "RefundPoolFixed: nothing to refund");

        contributions[msg.sender] = 0;
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "RefundPoolFixed: refund failed");
        emit Refunded(msg.sender, amount);
    }
}
