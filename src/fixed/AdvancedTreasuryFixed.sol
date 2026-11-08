// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title AdvancedTreasuryFixed
/// @notice Corrected treasury with an owner-controlled hook and CEI.
/// @dev Defense: `setHook` is restricted to the owner and `withdraw` is guarded
///      against reentrancy with the balance reset before the external call.
contract AdvancedTreasuryFixed is Ownable, ReentrancyGuard {
    /// @notice Recorded balance of each depositor.
    mapping(address => uint256) public balances;

    /// @notice Contract called when a user withdraws.
    address public hook;

    /// @notice Emitted when a deposit is recorded.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when the hook changes.
    event HookChanged(address indexed previousHook, address indexed newHook);

    /// @notice Set the deployer as owner.
    constructor() Ownable(msg.sender) { }

    /// @notice Deposit ETH into the treasury.
    function deposit() external payable {
        require(msg.value > 0, "AdvancedTreasuryFixed: zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Install the payout hook.
    /// @dev Defense: only the owner can change this critical parameter.
    /// @param newHook New hook address.
    function setHook(address newHook) external onlyOwner {
        require(newHook != address(0), "AdvancedTreasuryFixed: zero hook");
        emit HookChanged(hook, newHook);
        hook = newHook;
    }

    /// @notice Withdraw the caller's full balance through the configured hook.
    /// @dev Defense: balance reset before the call and `nonReentrant` guard.
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "AdvancedTreasuryFixed: nothing to withdraw");

        balances[msg.sender] = 0;

        (bool success,) = hook.call{ value: amount }("");
        require(success, "AdvancedTreasuryFixed: transfer failed");
    }

    /// @notice Total ETH held by the treasury.
    function treasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
