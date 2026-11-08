// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRefundPool {
    function contribute() external payable;
    function refund() external;
}

/// @title RefundPoolAttacker
/// @notice Contributor that rejects every ETH transfer.
/// @dev LAB USE ONLY. Its presence in the push-payment loop makes `refundAll`
///      revert for all contributors.
contract RefundPoolAttacker {
    IRefundPool public immutable pool;

    constructor(address poolAddress) {
        require(poolAddress != address(0), "RefundPoolAttacker: zero pool");
        pool = IRefundPool(poolAddress);
    }

    /// @notice Contribute to the pool on behalf of this contract.
    function contribute() external payable {
        require(msg.value > 0, "RefundPoolAttacker: zero amount");
        pool.contribute{ value: msg.value }();
    }

    /// @notice Ask the corrected pool for a refund; the transfer will fail here.
    function refundSelf() external {
        pool.refund();
    }

    /// @notice Always reject incoming ETH to block push refunds.
    receive() external payable {
        revert("RefundPoolAttacker: refund rejected");
    }
}
