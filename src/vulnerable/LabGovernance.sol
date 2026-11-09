// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// VULNERABLE BY DESIGN - LAB USE ONLY
contract LabGovernance {
    address public owner;

    address public treasury;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TreasuryChanged(address indexed previousTreasury, address indexed newTreasury);

    constructor() {
        owner = msg.sender;
        treasury = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        require(tx.origin == owner, "LabGovernance: not owner");
        require(newOwner != address(0), "LabGovernance: zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setTreasury(address newTreasury) external {
        require(tx.origin == owner, "LabGovernance: not owner");
        require(newTreasury != address(0), "LabGovernance: zero treasury");
        emit TreasuryChanged(treasury, newTreasury);
        treasury = newTreasury;
    }
}
