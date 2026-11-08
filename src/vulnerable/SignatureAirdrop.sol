// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title SignatureAirdrop
/// @notice ETH airdrop unlocked by an off-chain signature.
/// @dev VULNERABLE BY DESIGN - LAB USE ONLY
///      The signed message contains only the recipient and amount. It has no
///      nonce, no expiry and no domain separator, so the same signature can be
///      replayed indefinitely on this contract and on any copy of it.
contract SignatureAirdrop {
    using ECDSA for bytes32;

    /// @notice Address whose signature authorizes claims.
    address public immutable signer;

    /// @notice Emitted when a claim is paid.
    event Claimed(address indexed recipient, uint256 amount);

    /// @notice Configure the trusted signer.
    /// @param trustedSigner Address allowed to authorize claims.
    constructor(address trustedSigner) {
        require(trustedSigner != address(0), "SignatureAirdrop: zero signer");
        signer = trustedSigner;
    }

    /// @notice Claim an airdrop amount with a signature from `signer`.
    /// @dev Root cause: the digest does not bind a nonce, a deadline or the
    ///      contract/chain identity. The same signature stays valid forever.
    /// @param recipient Recipient of the airdrop.
    /// @param amount Amount to transfer in wei.
    /// @param signature Signature over `keccak256(abi.encodePacked(recipient, amount))`.
    function claim(address recipient, uint256 amount, bytes calldata signature) external {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(
            keccak256(abi.encodePacked(recipient, amount))
        );
        require(digest.recover(signature) == signer, "SignatureAirdrop: invalid signature");

        (bool success,) = recipient.call{ value: amount }("");
        require(success, "SignatureAirdrop: transfer failed");
        emit Claimed(recipient, amount);
    }

    /// @notice Fund the airdrop.
    function fund() external payable { }
}
