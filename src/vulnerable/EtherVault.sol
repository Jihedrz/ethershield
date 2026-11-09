// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// VULNERABLE BY DESIGN - LAB USE ONLY
contract EtherVault {
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "EtherVault: zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "EtherVault: nothing to withdraw");

        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "EtherVault: transfer failed");

        balances[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
