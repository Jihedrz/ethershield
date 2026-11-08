// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { SignatureExample } from "../../src/examples/SignatureExample.sol";

/// @title M1 signature tests
/// @notice Signs a digest off-chain and recovers the signer on-chain.
contract SignatureExampleTest is Test {
    uint256 internal constant SIGNER_KEY = 0xA11CE;

    function test_Signature_RecoversExpectedSigner() public {
        SignatureExample example = new SignatureExample();
        address signer = vm.addr(SIGNER_KEY);

        bytes32 digest = example.hashMessage(signer, 1 ether);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        assertEq(example.recover(digest, signature), signer, "recovered signer must match");
    }
}
