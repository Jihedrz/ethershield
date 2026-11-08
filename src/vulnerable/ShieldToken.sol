// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ShieldToken
/// @notice Simple ERC20 token used as lab reward currency.
/// @dev VULNERABLE BY DESIGN - LAB USE ONLY
///      `mint` has no access control: any address can create unlimited tokens.
contract ShieldToken is ERC20 {
    /// @notice Deploy the token with an initial supply credited to the deployer.
    /// @param initialSupply Initial supply in token units (18 decimals).
    constructor(uint256 initialSupply) ERC20("ShieldToken", "SHD") {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new tokens to an arbitrary address.
    /// @dev Root cause: no owner, role or allowlist check is performed.
    /// @param to Recipient of the newly minted tokens.
    /// @param amount Amount to mint in token units.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
