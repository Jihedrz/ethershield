// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LabGovernanceFixed {
    address public owner;

    address public treasury;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TreasuryChanged(address indexed previousTreasury, address indexed newTreasury);

    constructor() {
        owner = msg.sender;
        treasury = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "LabGovernanceFixed: not owner");
        require(newOwner != address(0), "LabGovernanceFixed: zero owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setTreasury(address newTreasury) external {
        require(msg.sender == owner, "LabGovernanceFixed: not owner");
        require(newTreasury != address(0), "LabGovernanceFixed: zero treasury");
        emit TreasuryChanged(treasury, newTreasury);
        treasury = newTreasury;
    }
}
