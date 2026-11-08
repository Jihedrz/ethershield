// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title PaymentExample
/// @notice Small contract used to demonstrate `payable`, `msg.sender` and transactions.
/// @dev Teaching example for module M1.
contract PaymentExample {
    /// @notice Last address that sent ETH.
    address public lastSender;

    /// @notice Last amount received in wei.
    uint256 public lastValue;

    /// @notice Total amount received in wei.
    uint256 public totalReceived;

    /// @notice Emitted when a payment is received.
    event Paid(address indexed from, uint256 amount);

    /// @notice Pay ETH through an explicit function.
    function pay() external payable {
        require(msg.value > 0, "PaymentExample: zero payment");
        _record(msg.sender, msg.value);
    }

    /// @notice Accept plain ETH transfers.
    receive() external payable {
        _record(msg.sender, msg.value);
    }

    /// @notice Record a payment and emit the corresponding event.
    function _record(address sender, uint256 amount) private {
        lastSender = sender;
        lastValue = amount;
        totalReceived += amount;
        emit Paid(sender, amount);
    }
}
