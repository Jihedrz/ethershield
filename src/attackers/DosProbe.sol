// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRefundPoolProbe {
    function refundAll() external;
}

/// @title DosProbe
/// @notice Calls `refundAll` from a helper contract so the expected revert can be
///         observed without aborting the caller transaction.
/// @dev LAB USE ONLY. The probe returns false when the pool is blocked.
contract DosProbe {
    /// @notice Attempt a global refund and report whether it succeeded.
    /// @param pool Address of the refund pool.
    /// @return success True if `refundAll` completed.
    function probe(address pool) external returns (bool success) {
        (success,) = pool.call(abi.encodeCall(IRefundPoolProbe.refundAll, ()));
    }
}
