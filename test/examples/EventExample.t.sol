// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { EventExample } from "../../src/examples/EventExample.sol";

/// @title M1 event tests
/// @notice Checks that an indexed event is emitted with the expected topic and data.
contract EventExampleTest is Test {
    event Deposit(address indexed from, uint256 amount);

    EventExample internal example;

    function setUp() public {
        example = new EventExample();
    }

    function test_Event_EmitsIndexedDeposit() public {
        vm.deal(address(this), 1 ether);

        vm.expectEmit(true, false, false, true, address(example));
        emit Deposit(address(this), 1 ether);

        example.deposit{ value: 1 ether }();
        assertEq(example.totalDeposited(), 1 ether);
    }
}
