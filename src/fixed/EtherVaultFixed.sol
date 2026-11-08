// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title EtherVaultFixed
/// @notice Corrected vault using Checks-Effects-Interactions and a reentrancy guard.
/// @dev Defense: the balance is reset before the external call and `nonReentrant`
///      blocks any nested withdrawal attempt.
contract EtherVaultFixed is ReentrancyGuard {
    /// @notice Recorded balance of each depositor.
    mapping(address => uint256) public balances;

    /// @notice Sum of all recorded balances.
    uint256 public totalDeposits;

    /// @notice Emitted when a user deposits ETH.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws ETH.
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Deposit ETH and credit the caller's balance.
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "EtherVaultFixed: zero deposit");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw the caller's full recorded balance.
    /// @dev Effects (balance reset) happen before the interaction (ETH transfer).
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "EtherVaultFixed: nothing to withdraw");

        balances[msg.sender] = 0;
        totalDeposits -= amount;

        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "EtherVaultFixed: transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Total ETH currently held by the vault.
    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
