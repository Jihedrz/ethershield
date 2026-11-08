// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title LabGovernanceFixed
/// @notice Corrected governance contract authenticating the immediate caller.
/// @dev Defense: every privileged function checks `msg.sender`, so a phishing
///      contract called by the owner is not treated as the owner.
contract LabGovernanceFixed {
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
    /// @dev Defense: `msg.sender` is the direct caller. The owner calling a
    ///      phishing contract no longer authorizes the nested call.
    /// @param newOwner New governance owner.
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "LabGovernanceFixed: not owner");
        require(newOwner != address(0), "LabGovernanceFixed: zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Change the treasury address.
    /// @dev Defense: same `msg.sender` authentication.
    /// @param newTreasury New treasury address.
    function setTreasury(address newTreasury) external {
        require(msg.sender == owner, "LabGovernanceFixed: not owner");
        require(newTreasury != address(0), "LabGovernanceFixed: zero treasury");
        emit TreasuryChanged(treasury, newTreasury);
        treasury = newTreasury;
    }
}
