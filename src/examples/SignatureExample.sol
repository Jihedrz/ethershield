// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title SignatureExample
/// @notice Small contract used to demonstrate ECDSA signature recovery.
/// @dev Teaching example for module M1.
contract SignatureExample {
    /// @notice Build the Ethereum signed-message digest for a simple payload.
    /// @param signer Address included in the payload.
    /// @param amount Amount included in the payload.
    /// @return digest Digest that the signer must sign.
    function hashMessage(address signer, uint256 amount) external pure returns (bytes32 digest) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encodePacked(signer, amount)));
    }

    /// @notice Recover the address that produced a signature.
    /// @param digest Digest that was signed.
    /// @param signature Signature bytes.
    /// @return signer Recovered signer address.
    function recover(bytes32 digest, bytes calldata signature)
        external
        pure
        returns (address signer)
    {
        return ECDSA.recover(digest, signature);
    }
}
