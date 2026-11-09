// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// VULNERABLE BY DESIGN - LAB USE ONLY
contract AdvancedTreasury {
    mapping(address => uint256) public balances;

    address public hook;

    event Deposited(address indexed user, uint256 amount);

    event HookChanged(address indexed previousHook, address indexed newHook);

    function deposit() external payable {
        require(msg.value > 0, "AdvancedTreasury: zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function setHook(address newHook) external {
        require(newHook != address(0), "AdvancedTreasury: zero hook");
        emit HookChanged(hook, newHook);
        hook = newHook;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "AdvancedTreasury: nothing to withdraw");

        (bool success,) = hook.call{ value: amount }("");
        require(success, "AdvancedTreasury: transfer failed");

        balances[msg.sender] = 0;
    }

    function treasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
