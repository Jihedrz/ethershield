// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title FrontRunLottery
/// @notice First participant to submit the solution of a public puzzle wins the prize.
/// @dev VULNERABLE BY DESIGN - LAB USE ONLY
///      The solution is sent in clear text. Any observer of the mempool can copy
///      it and publish the same transaction with a higher fee before the honest
///      participant, taking the prize.
contract FrontRunLottery {
    /// @notice Hash of the expected answer.
    bytes32 public immutable puzzleHash;

    /// @notice Prize held by the contract.
    uint256 public prize;

    /// @notice True once the prize has been claimed.
    bool public solved;

    /// @notice Emitted when the prize is paid.
    event Solved(address indexed winner, uint256 prize);

    /// @notice Deploy the lottery with a puzzle and an initial prize.
    /// @param answerHash `keccak256(abi.encodePacked(answer))`.
    constructor(bytes32 answerHash) payable {
        require(msg.value > 0, "FrontRunLottery: no prize");
        puzzleHash = answerHash;
        prize = msg.value;
    }

    /// @notice Submit the puzzle answer and claim the prize.
    /// @dev Root cause: the answer is public in calldata before inclusion, so
    ///      transaction ordering decides the winner.
    /// @param answer Plain answer to the puzzle.
    function solve(uint256 answer) external {
        require(!solved, "FrontRunLottery: already solved");
        require(keccak256(abi.encodePacked(answer)) == puzzleHash, "FrontRunLottery: wrong answer");

        solved = true;
        uint256 payout = address(this).balance;
        prize = 0;
        (bool success,) = msg.sender.call{ value: payout }("");
        require(success, "FrontRunLottery: transfer failed");
        emit Solved(msg.sender, payout);
    }
}
