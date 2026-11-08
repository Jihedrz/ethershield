// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RefundPool
/// @notice Pool that refunds every contributor in a single transaction.
/// @dev VULNERABLE BY DESIGN - LAB USE ONLY
///      `refundAll` pushes ETH to every contributor with a mandatory successful
///      call. One contributor that always reverts blocks refunds for everybody.
contract RefundPool {
    /// @notice Contributors in registration order.
    address[] public contributors;

    /// @notice Amount contributed by each address.
    mapping(address => uint256) public contributions;

    /// @notice Emitted when a contribution is recorded.
    event Contributed(address indexed contributor, uint256 amount);

    /// @notice Emitted when a contributor is refunded.
    event Refunded(address indexed contributor, uint256 amount);

    /// @notice Add ETH to the pool.
    function contribute() external payable {
        require(msg.value > 0, "RefundPool: zero contribution");
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    /// @notice Refund all contributors.
    /// @dev Root cause: unbounded push loop and mandatory success of each call.
    ///      A single reverting receiver blocks the whole refund.
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

    /// @notice Number of registered contributors.
    function contributorCount() external view returns (uint256) {
        return contributors.length;
    }
}
