// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { CommitRevealLottery } from "../../src/fixed/CommitRevealLottery.sol";

contract CommitRevealLotteryTest is Test {
    uint256 internal constant ANSWER = 42;
    uint256 internal constant PRIZE = 10 ether;
    address internal constant PLAYER = address(0xB0B);

    function testFuzz_CommitRevealWinsPrize(bytes32 salt) public {
        bytes32 puzzleHash = keccak256(abi.encodePacked(ANSWER));
        CommitRevealLottery lottery =
            new CommitRevealLottery{ value: PRIZE }(puzzleHash, 1 days, 1 days);

        bytes32 commitment = lottery.commitmentFor(PLAYER, ANSWER, salt);
        vm.prank(PLAYER);
        lottery.commit(commitment);
        vm.warp(block.timestamp + 1 days);
        vm.prank(PLAYER);
        lottery.reveal(ANSWER, salt);

        assertEq(PLAYER.balance, PRIZE);
        assertTrue(lottery.solved());
    }

    function test_RevertWhen_RevealBeforeCommitDeadline() public {
        bytes32 puzzleHash = keccak256(abi.encodePacked(ANSWER));
        CommitRevealLottery lottery =
            new CommitRevealLottery{ value: PRIZE }(puzzleHash, 1 days, 1 days);
        bytes32 salt = keccak256("salt");
        bytes32 commitment = lottery.commitmentFor(PLAYER, ANSWER, salt);
        vm.prank(PLAYER);
        lottery.commit(commitment);

        vm.prank(PLAYER);
        vm.expectRevert("CommitRevealLottery: commit phase ongoing");
        lottery.reveal(ANSWER, salt);
    }

    function test_RevertWhen_RevealAfterRevealDeadline() public {
        bytes32 puzzleHash = keccak256(abi.encodePacked(ANSWER));
        CommitRevealLottery lottery =
            new CommitRevealLottery{ value: PRIZE }(puzzleHash, 1 days, 1 days);
        bytes32 salt = keccak256("salt");
        bytes32 commitment = lottery.commitmentFor(PLAYER, ANSWER, salt);
        vm.prank(PLAYER);
        lottery.commit(commitment);

        vm.warp(block.timestamp + 2 days + 1);
        vm.prank(PLAYER);
        vm.expectRevert("CommitRevealLottery: reveal phase over");
        lottery.reveal(ANSWER, salt);
    }
}
