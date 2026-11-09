// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CommitRevealLottery {
    bytes32 public immutable puzzleHash;

    uint256 public immutable commitDeadline;

    uint256 public immutable revealDeadline;

    mapping(address => bytes32) public commitments;

    bool public solved;

    event Committed(address indexed participant, bytes32 commitment);

    event Solved(address indexed winner, uint256 prize);

    constructor(bytes32 answerHash, uint256 commitDuration, uint256 revealDuration) payable {
        require(msg.value > 0, "CommitRevealLottery: no prize");
        require(commitDuration > 0, "CommitRevealLottery: zero commit duration");
        require(revealDuration > 0, "CommitRevealLottery: zero reveal duration");
        puzzleHash = answerHash;
        commitDeadline = block.timestamp + commitDuration;
        revealDeadline = commitDeadline + revealDuration;
    }

    function commit(bytes32 commitment) external {
        require(block.timestamp < commitDeadline, "CommitRevealLottery: commit phase over");
        require(commitment != bytes32(0), "CommitRevealLottery: empty commitment");
        commitments[msg.sender] = commitment;
        emit Committed(msg.sender, commitment);
    }

    function reveal(uint256 answer, bytes32 salt) external {
        require(block.timestamp >= commitDeadline, "CommitRevealLottery: commit phase ongoing");
        require(block.timestamp <= revealDeadline, "CommitRevealLottery: reveal phase over");
        require(!solved, "CommitRevealLottery: already solved");
        require(
            commitments[msg.sender] == commitmentFor(msg.sender, answer, salt),
            "CommitRevealLottery: bad commitment"
        );
        require(
            keccak256(abi.encodePacked(answer)) == puzzleHash, "CommitRevealLottery: wrong answer"
        );

        solved = true;
        commitments[msg.sender] = bytes32(0);
        uint256 payout = address(this).balance;
        (bool success,) = msg.sender.call{ value: payout }("");
        require(success, "CommitRevealLottery: transfer failed");
        emit Solved(msg.sender, payout);
    }

    function commitmentFor(address participant, uint256 answer, bytes32 salt)
        public
        view
        returns (bytes32 commitment)
    {
        return keccak256(abi.encode(answer, salt, participant, address(this)));
    }
}
