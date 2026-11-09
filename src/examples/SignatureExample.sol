// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignatureExample {
    function hashMessage(address signer, uint256 amount) external pure returns (bytes32 digest) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encodePacked(signer, amount)));
    }

    function recover(bytes32 digest, bytes calldata signature)
        external
        pure
        returns (address signer)
    {
        return ECDSA.recover(digest, signature);
    }
}
