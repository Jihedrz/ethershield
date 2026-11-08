// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title StorageExample
/// @notice Small contract used to inspect storage slots and variable packing.
/// @dev Teaching example for module M1. Layout:
///      slot 0: `value`
///      slot 1: `smallA` (low 128 bits) and `smallB` (high 128 bits)
///      slot 2: `owner`
contract StorageExample {
    /// @notice Full-width value stored in slot 0.
    uint256 public value;

    /// @notice First 128-bit value packed in slot 1.
    uint128 public smallA;

    /// @notice Second 128-bit value packed in slot 1.
    uint128 public smallB;

    /// @notice Address stored in slot 2.
    address public owner;

    /// @notice Set all example values.
    /// @param newValue Value for slot 0.
    /// @param newSmallA Low half of slot 1.
    /// @param newSmallB High half of slot 1.
    /// @param newOwner Value for slot 2.
    function setValues(uint256 newValue, uint128 newSmallA, uint128 newSmallB, address newOwner)
        external
    {
        value = newValue;
        smallA = newSmallA;
        smallB = newSmallB;
        owner = newOwner;
    }
}
