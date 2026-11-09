// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// VULNERABLE BY DESIGN - LAB USE ONLY
contract RefundPool {
    address[] public contributors;

    mapping(address => uint256) public contributions;

    event Contributed(address indexed contributor, uint256 amount);

    event Refunded(address indexed contributor, uint256 amount);

    function contribute() external payable {
        require(msg.value > 0, "RefundPool: zero contribution");
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    function refundAll() external {
        uint256 length = contributors.length;
        for (uint256 i = 0; i < length; i++) {
            address contributor = contributors[i];
            uint256 amount = contributions[contributor];
            contributions[contributor] = 0;
            (bool success,) = contributor.call{ value: amount }("");
            require(success, "RefundPool: refund failed");
            emit Refunded(contributor, amount);
        }
    }

    function contributorCount() external view returns (uint256) {
        return contributors.length;
    }
}
