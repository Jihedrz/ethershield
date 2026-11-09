// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GasExample {
    uint256 public storedValue;

    uint256[] public storedValues;

    function setStored(uint256 value) external {
        storedValue = value;
    }

    function storeMany(uint256 count) external {
        for (uint256 i = 0; i < count; i++) {
            storedValues.push(i);
        }
    }

    function sumMemory(uint256 count) external pure returns (uint256 total) {
        uint256[] memory local = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            local[i] = i;
            total += local[i];
        }
    }

    function gasLeft() external view returns (uint256 remaining) {
        return gasleft();
    }
}
