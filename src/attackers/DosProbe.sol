// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRefundPoolProbe {
    function refundAll() external;
}

contract DosProbe {
    function probe(address pool) external returns (bool success) {
        (success,) = pool.call(abi.encodeCall(IRefundPoolProbe.refundAll, ()));
    }
}
