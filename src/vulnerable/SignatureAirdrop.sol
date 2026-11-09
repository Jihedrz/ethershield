// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// VULNERABLE BY DESIGN - LAB USE ONLY
contract SignatureAirdrop {
    using ECDSA for bytes32;

    address public immutable signer;

    event Claimed(address indexed recipient, uint256 amount);

    constructor(address trustedSigner) {
        require(trustedSigner != address(0), "SignatureAirdrop: zero signer");
        signer = trustedSigner;
    }

    function claim(address recipient, uint256 amount, bytes calldata signature) external {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(
            keccak256(abi.encodePacked(recipient, amount))
        );
        require(digest.recover(signature) == signer, "SignatureAirdrop: invalid signature");

        (bool success,) = recipient.call{ value: amount }("");
        require(success, "SignatureAirdrop: transfer failed");
        emit Claimed(recipient, amount);
    }

    function fund() external payable { }
}
