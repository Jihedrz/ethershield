// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract SignatureAirdropFixed is EIP712 {
    address public immutable signer;

    mapping(address => uint256) public nonces;

    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address recipient,uint256 amount,uint256 nonce,uint256 deadline)");

    event Claimed(address indexed recipient, uint256 amount, uint256 nonce);

    constructor(address trustedSigner) EIP712("SignatureAirdrop", "1") {
        require(trustedSigner != address(0), "SignatureAirdropFixed: zero signer");
        signer = trustedSigner;
    }

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

    function hashClaim(address recipient, uint256 amount, uint256 nonce, uint256 deadline)
        public
        view
        returns (bytes32 digest)
    {
        bytes32 structHash =
            keccak256(abi.encode(CLAIM_TYPEHASH, recipient, amount, nonce, deadline));
        return _hashTypedDataV4(structHash);
    }

    function fund() external payable { }
}
