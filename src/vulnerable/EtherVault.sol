// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title EtherVault
/// @notice Vault that accepts ETH deposits and lets each user withdraw their balance.
/// @dev VULNERABLE BY DESIGN - LAB USE ONLY
///      The contract sends ETH before updating the internal balance. A malicious
///      receiver can re-enter `withdraw` and drain the vault.
contract EtherVault {
    /// @notice Recorded balance of each depositor.
    mapping(address => uint256) public balances;

    /// @notice Emitted when a user deposits ETH.
    /// @param user Depositor address.
    /// @param amount Amount deposited in wei.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws ETH.
    /// @param user Withdrawer address.
    /// @param amount Amount withdrawn in wei.
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Deposit ETH and credit the caller's balance.
    function deposit() external payable {
        require(msg.value > 0, "EtherVault: zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw the caller's full recorded balance.
    /// @dev Root cause: the external call happens before `balances` is reset.
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "EtherVault: nothing to withdraw");

        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "EtherVault: transfer failed");

        balances[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Total ETH currently held by the vault.
    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
