// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { StorageExample } from "../../src/examples/StorageExample.sol";

contract StorageExampleTest is Test {
    StorageExample internal example;

    function setUp() public {
        example = new StorageExample();
    }

    function test_Storage_ReadsSlotsAndPackedValues() public {
        uint128 smallA = 0x1111;
        uint128 smallB = 0x2222;
        address owner = address(0xCAFE);

        example.setValues(123, smallA, smallB, owner);

        bytes32 slot0 = vm.load(address(example), bytes32(uint256(0)));
        assertEq(uint256(slot0), 123, "slot 0 must hold value");

        bytes32 slot1 = vm.load(address(example), bytes32(uint256(1)));
        assertEq(uint128(uint256(slot1)), smallA, "low half of slot 1 must hold smallA");
        assertEq(uint128(uint256(slot1) >> 128), smallB, "high half of slot 1 must hold smallB");

        bytes32 slot2 = vm.load(address(example), bytes32(uint256(2)));
        assertEq(address(uint160(uint256(slot2))), owner, "slot 2 must hold owner");
    }
}
