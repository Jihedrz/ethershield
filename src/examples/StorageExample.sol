// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract StorageExample {
    uint256 public value;

    uint128 public smallA;

    uint128 public smallB;

    address public owner;

    function setValues(uint256 newValue, uint128 newSmallA, uint128 newSmallB, address newOwner)
        external
    {
        value = newValue;
        smallA = newSmallA;
        smallB = newSmallB;
        owner = newOwner;
    }
}
