// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title LabGovernance
/// @notice Minimal governance contract owning a lab treasury address.
/// @dev VULNERABLE BY DESIGN - LAB USE ONLY
///      Ownership transfer authenticates with `tx.origin`. If the owner is
///      tricked into calling a malicious contract, that contract becomes the
///      origin of the call and can transfer ownership to the attacker.
contract LabGovernance {
    /// @notice Current governance owner.
    address public owner;

    /// @notice Address controlled by the governance.
    address public treasury;

    /// @notice Emitted when ownership changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the treasury address changes.
    event TreasuryChanged(address indexed previousTreasury, address indexed newTreasury);

    /// @notice Set the deployer as initial owner and treasury.
    constructor() {
        owner = msg.sender;
        treasury = msg.sender;
    }

    /// @notice Transfer governance ownership.
    /// @dev Root cause: `tx.origin` is the EOA that started the transaction, not
    ///      the immediate caller. A phishing contract called by the owner passes
    ///      this check.
    /// @param newOwner New governance owner.
    function transferOwnership(address newOwner) external {
        require(tx.origin == owner, "LabGovernance: not owner");
        require(newOwner != address(0), "LabGovernance: zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Change the treasury address.
    /// @dev Root cause: same `tx.origin` authentication weakness.
    /// @param newTreasury New treasury address.
    function setTreasury(address newTreasury) external {
        require(tx.origin == owner, "LabGovernance: not owner");
        require(newTreasury != address(0), "LabGovernance: zero treasury");
        emit TreasuryChanged(treasury, newTreasury);
        treasury = newTreasury;
    }
}
