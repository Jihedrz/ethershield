// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @title SignatureAirdropFixed
/// @notice Corrected airdrop using EIP-712, per-recipient nonces and deadlines.
/// @dev Defense: the signed digest is bound to this contract, the current chain,
///      a recipient nonce and an expiration timestamp. A used signature cannot
///      be replayed on this contract or on another deployment.
contract SignatureAirdropFixed is EIP712 {
    /// @notice Address whose signature authorizes claims.
    address public immutable signer;

    /// @notice Next nonce expected for each recipient.
    mapping(address => uint256) public nonces;

    /// @notice EIP-712 type hash of a claim.
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address recipient,uint256 amount,uint256 nonce,uint256 deadline)");

    /// @notice Emitted when a claim is paid.
    event Claimed(address indexed recipient, uint256 amount, uint256 nonce);

    /// @notice Configure the trusted signer and the EIP-712 domain.
    /// @param trustedSigner Address allowed to authorize claims.
    constructor(address trustedSigner) EIP712("SignatureAirdrop", "1") {
        require(trustedSigner != address(0), "SignatureAirdropFixed: zero signer");
        signer = trustedSigner;
    }

    /// @notice Claim an airdrop amount with a signature from `signer`.
    /// @dev Defense: nonce increments before the transfer and the deadline is
    ///      checked. The EIP-712 domain includes `address(this)` and `block.chainid`.
    /// @param recipient Recipient of the airdrop.
    /// @param amount Amount to transfer in wei.
    /// @param deadline Last timestamp at which the signature is valid.
    /// @param signature EIP-712 signature over the claim struct.
    function claim(address recipient, uint256 amount, uint256 deadline, bytes calldata signature)
        external
    {
        require(block.timestamp <= deadline, "SignatureAirdropFixed: expired");

        uint256 nonce = nonces[recipient];
        bytes32 digest = hashClaim(recipient, amount, nonce, deadline);
        require(
            ECDSA.recover(digest, signature) == signer, "SignatureAirdropFixed: invalid signature"
        );

        nonces[recipient] = nonce + 1;

        (bool success,) = recipient.call{ value: amount }("");
        require(success, "SignatureAirdropFixed: transfer failed");
        emit Claimed(recipient, amount, nonce);
    }

    /// @notice Compute the EIP-712 digest expected for a claim.
    /// @param recipient Recipient of the airdrop.
    /// @param amount Amount to transfer in wei.
    /// @param nonce Nonce of the recipient.
    /// @param deadline Last timestamp at which the signature is valid.
    /// @return digest EIP-712 typed-data digest.
    function hashClaim(address recipient, uint256 amount, uint256 nonce, uint256 deadline)
        public
        view
        returns (bytes32 digest)
    {
        bytes32 structHash =
            keccak256(abi.encode(CLAIM_TYPEHASH, recipient, amount, nonce, deadline));
        return _hashTypedDataV4(structHash);
    }

    /// @notice Fund the airdrop.
    function fund() external payable { }
}
