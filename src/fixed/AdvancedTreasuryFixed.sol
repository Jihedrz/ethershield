// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AdvancedTreasuryFixed is Ownable, ReentrancyGuard {
    mapping(address => uint256) public balances;

    address public hook;

    event Deposited(address indexed user, uint256 amount);

    event HookChanged(address indexed previousHook, address indexed newHook);

    constructor() Ownable(msg.sender) { }

    function deposit() external payable {
        require(msg.value > 0, "AdvancedTreasuryFixed: zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function setHook(address newHook) external onlyOwner {
        require(newHook != address(0), "AdvancedTreasuryFixed: zero hook");
        emit HookChanged(hook, newHook);
        hook = newHook;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "AdvancedTreasuryFixed: nothing to withdraw");

        balances[msg.sender] = 0;

        (bool success,) = hook.call{ value: amount }("");
        require(success, "AdvancedTreasuryFixed: transfer failed");
    }

    function treasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
