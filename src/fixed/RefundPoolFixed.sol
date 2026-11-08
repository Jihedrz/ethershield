// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RefundPoolFixed
/// @notice Corrected pool using pull payments.
/// @dev Defense: there is no loop over contributors. Each user withdraws their
///      own balance, so a reverting receiver can only block their own refund.
contract RefundPoolFixed {
    /// @notice Amount contributed by each address.
    mapping(address => uint256) public contributions;

    /// @notice Emitted when a contribution is recorded.
    event Contributed(address indexed contributor, uint256 amount);

    /// @notice Emitted when a contributor withdraws their refund.
    event Refunded(address indexed contributor, uint256 amount);

    /// @notice Add ETH to the pool.
    function contribute() external payable {
        require(msg.value > 0, "RefundPoolFixed: zero contribution");
        contributions[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    /// @notice Withdraw the caller's own contribution.
    /// @dev Effects happen before the interaction, so reentrancy cannot replay it.
    function refund() external {
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "RefundPoolFixed: nothing to refund");

        contributions[msg.sender] = 0;
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "RefundPoolFixed: refund failed");
        emit Refunded(msg.sender, amount);
    }
}
