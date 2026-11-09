// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// VULNERABLE BY DESIGN - LAB USE ONLY
contract ShieldToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("ShieldToken", "SHD") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
