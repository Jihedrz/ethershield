// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title EventExample
/// @notice Small contract used to demonstrate indexed events.
/// @dev Teaching example for module M1.
contract EventExample {
    /// @notice Emitted on every deposit.
    /// @param from Depositor address, indexed for filtering.
    /// @param amount Amount deposited in wei.
    event Deposit(address indexed from, uint256 amount);

    /// @notice Total ETH deposited through this contract.
    uint256 public totalDeposited;

    /// @notice Deposit ETH and emit an indexed event.
    function deposit() external payable {
        require(msg.value > 0, "EventExample: zero deposit");
        totalDeposited += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
