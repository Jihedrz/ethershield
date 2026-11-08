// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GasExample
/// @notice Small contract used to compare the cost of storage writes and memory work.
/// @dev Teaching example for module M1. Not used by the security scenarios.
contract GasExample {
    /// @notice Value persisted in storage.
    uint256 public storedValue;

    /// @notice Dynamic array persisted in storage.
    uint256[] public storedValues;

    /// @notice Write one value to storage.
    /// @param value Value to persist.
    function setStored(uint256 value) external {
        storedValue = value;
    }

    /// @notice Append `count` values to a storage array.
    /// @param count Number of values to append.
    function storeMany(uint256 count) external {
        for (uint256 i = 0; i < count; i++) {
            storedValues.push(i);
        }
    }

    /// @notice Sum `count` values using a memory array only.
    /// @param count Number of values to sum.
    /// @return total Sum of the values.
    function sumMemory(uint256 count) external pure returns (uint256 total) {
        uint256[] memory local = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            local[i] = i;
            total += local[i];
        }
    }

    /// @notice Remaining gas at the time of the call.
    /// @return remaining Gas left in the current execution frame.
    function gasLeft() external view returns (uint256 remaining) {
        return gasleft();
    }
}
