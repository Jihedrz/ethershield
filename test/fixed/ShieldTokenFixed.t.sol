// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ShieldTokenFixed } from "../../src/fixed/ShieldTokenFixed.sol";

/// @title ShieldTokenFixed non-regression and fuzz tests
/// @notice Verifies role-gated minting and normal token behavior.
contract ShieldTokenFixedTest is Test {
    ShieldTokenFixed internal token;

    function setUp() public {
        token = new ShieldTokenFixed(1_000 ether);
    }

    function test_AdminCanMint() public {
        token.mint(address(0xB0B), 10 ether);
        assertEq(token.balanceOf(address(0xB0B)), 10 ether);
        assertEq(token.totalSupply(), 1_010 ether);
    }

    function testFuzz_NonMinterCannotMint(address caller, uint96 rawAmount) public {
        vm.assume(caller != address(this));
        uint256 amount = bound(uint256(rawAmount), 1, 1_000_000 ether);

        vm.prank(caller);
        vm.expectRevert();
        token.mint(caller, amount);

        assertEq(token.balanceOf(caller), 0);
        assertEq(token.totalSupply(), 1_000 ether);
    }

    function test_TransferMovesTokens() public {
        token.transfer(address(0xB0B), 5 ether);
        assertEq(token.balanceOf(address(0xB0B)), 5 ether);
        assertEq(token.balanceOf(address(this)), 995 ether);
    }
}
