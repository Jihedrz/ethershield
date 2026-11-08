// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { GasExample } from "../../src/examples/GasExample.sol";

/// @title M1 gas tests
/// @notice Measures the cost of storage writes against pure memory work.
contract GasExampleTest is Test {
    GasExample internal example;

    function setUp() public {
        example = new GasExample();
    }

    function test_Gas_StorageWriteCostsMoreThanMemoryWork() public {
        uint256 before = gasleft();
        example.storeMany(20);
        uint256 storageGas = before - gasleft();

        before = gasleft();
        example.sumMemory(20);
        uint256 memoryGas = before - gasleft();

        assertGt(storageGas, memoryGas, "storage writes must cost more than memory work");
    }

    function test_Gas_FirstStorageWriteCostsAtLeastTwentyThousand() public {
        uint256 before = gasleft();
        example.setStored(1);
        uint256 used = before - gasleft();

        assertGt(used, 20_000, "cold zero-to-nonzero SSTORE must cost at least 20k gas");
    }
}
