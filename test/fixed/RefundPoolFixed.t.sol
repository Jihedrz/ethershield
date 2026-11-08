// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { RefundPoolFixed } from "../../src/fixed/RefundPoolFixed.sol";

/// @title RefundPoolFixed handler
/// @notice Drives contributions and refunds for invariant testing.
contract RefundPoolFixedHandler is Test {
    receive() external payable { }

    RefundPoolFixed public immutable pool;
    address[] public actors;
    uint256 public ghostSum;

    constructor(RefundPoolFixed poolAddress) {
        pool = poolAddress;
        actors.push(address(0xB1));
        actors.push(address(0xB2));
        actors.push(address(0xB3));
    }

    /// @notice Contribute a bounded amount for a pseudo-random actor.
    function contribute(uint256 actorSeed, uint256 amount) external {
        address actor = actors[bound(actorSeed, 0, actors.length - 1)];
        amount = bound(amount, 1, 10 ether);
        vm.deal(actor, amount);
        vm.prank(actor);
        pool.contribute{ value: amount }();
        ghostSum += amount;
    }

    /// @notice Refund the full contribution of a pseudo-random actor.
    function refund(uint256 actorSeed) external {
        address actor = actors[bound(actorSeed, 0, actors.length - 1)];
        uint256 amount = pool.contributions(actor);
        if (amount == 0) {
            return;
        }
        vm.prank(actor);
        pool.refund();
        ghostSum -= amount;
    }
}

/// @title RefundPoolFixed non-regression, fuzz and invariant tests
/// @notice Verifies pull payments and the accounting invariant.
contract RefundPoolFixedTest is Test {
    receive() external payable { }

    RefundPoolFixed internal pool;

    function setUp() public {
        pool = new RefundPoolFixed();
    }

    function test_ContributeAndRefund() public {
        vm.deal(address(this), 1 ether);
        pool.contribute{ value: 1 ether }();
        assertEq(pool.contributions(address(this)), 1 ether);

        pool.refund();
        assertEq(pool.contributions(address(this)), 0);
        assertEq(address(pool).balance, 0);
    }

    function testFuzz_ContributeRefundRoundTrip(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 100 ether);
        vm.deal(address(this), amount);

        pool.contribute{ value: amount }();
        assertEq(pool.contributions(address(this)), amount);
        assertEq(address(pool).balance, amount);

        pool.refund();
        assertEq(pool.contributions(address(this)), 0);
        assertEq(address(pool).balance, 0);
    }

    function test_RevertWhen_RefundWithoutContribution() public {
        vm.expectRevert("RefundPoolFixed: nothing to refund");
        pool.refund();
    }
}

/// @title RefundPoolFixed invariant tests
/// @notice The pool balance must always cover all recorded contributions.
contract RefundPoolFixedInvariantTest is Test {
    RefundPoolFixed internal pool;
    RefundPoolFixedHandler internal handler;

    function setUp() public {
        pool = new RefundPoolFixed();
        handler = new RefundPoolFixedHandler(pool);
        targetContract(address(handler));
    }

    /// @notice Invariant: balance covers the ghost sum of contributions.
    function invariant_BalanceCoversContributions() public view {
        assertGe(address(pool).balance, handler.ghostSum());
    }
}
