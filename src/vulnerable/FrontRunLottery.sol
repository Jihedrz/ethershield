// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// VULNERABLE BY DESIGN - LAB USE ONLY
contract FrontRunLottery {
    bytes32 public immutable puzzleHash;

    uint256 public prize;

    bool public solved;

    event Solved(address indexed winner, uint256 prize);

    constructor(bytes32 answerHash) payable {
        require(msg.value > 0, "FrontRunLottery: no prize");
        puzzleHash = answerHash;
        prize = msg.value;
    }

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
