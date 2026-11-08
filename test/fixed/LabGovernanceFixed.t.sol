// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { LabGovernanceFixed } from "../../src/fixed/LabGovernanceFixed.sol";

/// @title LabGovernanceFixed non-regression and fuzz tests
/// @notice Verifies that only the owner can transfer ownership or change the treasury.
contract LabGovernanceFixedTest is Test {
    LabGovernanceFixed internal governance;

    function setUp() public {
        governance = new LabGovernanceFixed();
    }

    function testFuzz_OwnerCanTransferOwnership(address newOwner) public {
        vm.assume(newOwner != address(0));

        governance.transferOwnership(newOwner);
        assertEq(governance.owner(), newOwner);
    }

    function testFuzz_NonOwnerCannotTransferOwnership(address caller, address newOwner) public {
        vm.assume(caller != address(this));
        vm.assume(newOwner != address(0));

        vm.prank(caller);
        vm.expectRevert("LabGovernanceFixed: not owner");
        governance.transferOwnership(newOwner);

        assertEq(governance.owner(), address(this));
    }

    function testFuzz_NonOwnerCannotChangeTreasury(address caller, address newTreasury) public {
        vm.assume(caller != address(this));
        vm.assume(newTreasury != address(0));

        vm.prank(caller);
        vm.expectRevert("LabGovernanceFixed: not owner");
        governance.setTreasury(newTreasury);

        assertEq(governance.treasury(), address(this));
    }
}
