// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { SignatureAirdropFixed } from "../../src/fixed/SignatureAirdropFixed.sol";

/// @title SignatureAirdropFixed non-regression and fuzz tests
/// @notice Verifies valid claims, nonce progression and expiration.
contract SignatureAirdropFixedTest is Test {
    uint256 internal constant SIGNER_KEY = 0xA11CE;
    address internal constant RECIPIENT = address(0xB0B);

    function testFuzz_ValidClaimPaysOnce(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 10 ether);
        address signer = vm.addr(SIGNER_KEY);
        SignatureAirdropFixed airdrop = new SignatureAirdropFixed(signer);
        vm.deal(address(airdrop), amount);

        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest = airdrop.hashClaim(RECIPIENT, amount, 0, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        airdrop.claim(RECIPIENT, amount, deadline, signature);

        assertEq(RECIPIENT.balance, amount);
        assertEq(airdrop.nonces(RECIPIENT), 1);
        assertEq(address(airdrop).balance, 0);
    }

    function test_NonceIncrementsForEachClaim() public {
        address signer = vm.addr(SIGNER_KEY);
        SignatureAirdropFixed airdrop = new SignatureAirdropFixed(signer);
        vm.deal(address(airdrop), 3 ether);

        uint256 deadline = block.timestamp + 1 days;
        for (uint256 nonce = 0; nonce < 3; nonce++) {
            bytes32 digest = airdrop.hashClaim(RECIPIENT, 1 ether, nonce, deadline);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_KEY, digest);
            airdrop.claim(RECIPIENT, 1 ether, deadline, abi.encodePacked(r, s, v));
        }

        assertEq(airdrop.nonces(RECIPIENT), 3);
        assertEq(RECIPIENT.balance, 3 ether);
    }
}
