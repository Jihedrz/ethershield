// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract EtherVaultFixed is ReentrancyGuard {
    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    event Deposited(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable nonReentrant {
        require(msg.value > 0, "EtherVaultFixed: zero deposit");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "EtherVaultFixed: nothing to withdraw");

        balances[msg.sender] = 0;
        totalDeposits -= amount;

        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "EtherVaultFixed: transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
