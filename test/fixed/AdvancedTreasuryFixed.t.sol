// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { AdvancedTreasuryFixed } from "../../src/fixed/AdvancedTreasuryFixed.sol";

/// @title AdvancedTreasuryFixed non-regression and fuzz tests
/// @notice Verifies owner-only hook configuration and normal withdrawals.
contract AdvancedTreasuryFixedTest is Test {
    AdvancedTreasuryFixed internal treasury;

    function setUp() public {
        treasury = new AdvancedTreasuryFixed();
        treasury.setHook(address(0xB0B));
    }

    function testFuzz_DepositWithdrawRoundTrip(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 100 ether);
        vm.deal(address(this), amount);

        treasury.deposit{ value: amount }();
        assertEq(treasury.balances(address(this)), amount);

        treasury.withdraw();
        assertEq(treasury.balances(address(this)), 0);
        assertEq(address(treasury).balance, 0);
    }

    function testFuzz_NonOwnerCannotSetHook(address caller, address newHook) public {
        vm.assume(caller != address(this));
        vm.assume(newHook != address(0));

        vm.prank(caller);
        vm.expectRevert();
        treasury.setHook(newHook);

        assertEq(treasury.hook(), address(0xB0B));
    }
}
