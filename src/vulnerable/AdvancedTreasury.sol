// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AdvancedTreasury
/// @notice Treasury with a configurable payout hook.
/// @dev VULNERABLE BY DESIGN - LAB USE ONLY
///      Two weaknesses combine:
///      1. `setHook` is public, so anyone can install a malicious hook.
///      2. `withdraw` calls the hook before resetting the user's balance, so the
///         hook can re-enter and drain other deposits.
contract AdvancedTreasury {
    /// @notice Recorded balance of each depositor.
    mapping(address => uint256) public balances;

    /// @notice Contract called when a user withdraws.
    address public hook;

    /// @notice Emitted when a deposit is recorded.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when the hook changes.
    event HookChanged(address indexed previousHook, address indexed newHook);

    /// @notice Deposit ETH into the treasury.
    function deposit() external payable {
        require(msg.value > 0, "AdvancedTreasury: zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Install the payout hook.
    /// @dev Root cause 1: missing access control on a critical parameter.
    /// @param newHook New hook address.
    function setHook(address newHook) external {
        require(newHook != address(0), "AdvancedTreasury: zero hook");
        emit HookChanged(hook, newHook);
        hook = newHook;
    }

    /// @notice Withdraw the caller's full balance through the configured hook.
    /// @dev Root cause 2: state is updated after the external call, enabling
    ///      reentrancy from the hook.
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "AdvancedTreasury: nothing to withdraw");

        (bool success,) = hook.call{ value: amount }("");
        require(success, "AdvancedTreasury: transfer failed");

        balances[msg.sender] = 0;
    }

    /// @notice Total ETH held by the treasury.
    function treasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
