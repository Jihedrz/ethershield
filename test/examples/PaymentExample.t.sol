// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { PaymentExample } from "../../src/examples/PaymentExample.sol";

/// @title M1 payment tests
/// @notice Demonstrates `payable`, `msg.sender`, explicit calls and plain ETH transfers.
contract PaymentExampleTest is Test {
    PaymentExample internal example;

    function setUp() public {
        example = new PaymentExample();
        vm.deal(address(this), 1 ether);
    }

    function test_Payment_RecordsSenderAndValue() public {
        example.pay{ value: 0.4 ether }();

        assertEq(example.lastSender(), address(this), "msg.sender must be recorded");
        assertEq(example.lastValue(), 0.4 ether, "value must be recorded");
        assertEq(example.totalReceived(), 0.4 ether, "total must be updated");
    }

    function test_Payment_ReceiveFallbackAcceptsPlainTransfer() public {
        (bool success,) = address(example).call{ value: 0.6 ether }("");
        assertTrue(success, "plain transfer must succeed");
        assertEq(example.lastSender(), address(this), "msg.sender must be recorded");
        assertEq(example.lastValue(), 0.6 ether, "value must be recorded");
        assertEq(example.totalReceived(), 0.6 ether, "total must be updated");
    }
}
