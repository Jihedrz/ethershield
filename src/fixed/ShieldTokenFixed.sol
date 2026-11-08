// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title ShieldTokenFixed
/// @notice Corrected token where minting requires an explicit role.
/// @dev Defense: `MINTER_ROLE` is required for minting and is granted only to the
///      deployer at construction time. New minters must be added by the admin.
contract ShieldTokenFixed is ERC20, AccessControl {
    /// @notice Role allowed to mint new tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Deploy the token and grant admin and minter roles to the deployer.
    /// @param initialSupply Initial supply in token units (18 decimals).
    constructor(uint256 initialSupply) ERC20("ShieldToken", "SHD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new tokens to an arbitrary address.
    /// @dev Defense: only an account holding `MINTER_ROLE` can call this function.
    /// @param to Recipient of the newly minted tokens.
    /// @param amount Amount to mint in token units.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
