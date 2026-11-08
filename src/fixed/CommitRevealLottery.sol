// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title CommitRevealLottery
/// @notice Corrected lottery using a commit-reveal scheme.
/// @dev Defense: participants commit to a salted hash during the commit phase and
///      only reveal after the commit deadline. An observer cannot copy a valid
///      answer because the commitment is bound to the sender, the salt and this
///      contract. Residual limits: validators can still censor or delay
///      transactions, and a participant may choose not to reveal.
contract CommitRevealLottery {
    /// @notice Hash of the expected answer.
    bytes32 public immutable puzzleHash;

    /// @notice Timestamp after which commits are rejected.
    uint256 public immutable commitDeadline;

    /// @notice Timestamp after which reveals are rejected.
    uint256 public immutable revealDeadline;

    /// @notice Commitment of each participant.
    mapping(address => bytes32) public commitments;

    /// @notice True once the prize has been claimed.
    bool public solved;

    /// @notice Emitted when a commitment is recorded.
    event Committed(address indexed participant, bytes32 commitment);

    /// @notice Emitted when the prize is paid.
    event Solved(address indexed winner, uint256 prize);

    /// @notice Deploy the lottery with a puzzle, a prize and two phases.
    /// @param answerHash `keccak256(abi.encodePacked(answer))`.
    /// @param commitDuration Duration of the commit phase in seconds.
    /// @param revealDuration Duration of the reveal phase in seconds.
    constructor(bytes32 answerHash, uint256 commitDuration, uint256 revealDuration) payable {
        require(msg.value > 0, "CommitRevealLottery: no prize");
        require(commitDuration > 0, "CommitRevealLottery: zero commit duration");
        require(revealDuration > 0, "CommitRevealLottery: zero reveal duration");
        puzzleHash = answerHash;
        commitDeadline = block.timestamp + commitDuration;
        revealDeadline = commitDeadline + revealDuration;
    }

    /// @notice Record a salted commitment to the answer.
    /// @param commitment `commitmentFor(msg.sender, answer, salt)`.
    function commit(bytes32 commitment) external {
        require(block.timestamp < commitDeadline, "CommitRevealLottery: commit phase over");
        require(commitment != bytes32(0), "CommitRevealLottery: empty commitment");
        commitments[msg.sender] = commitment;
        emit Committed(msg.sender, commitment);
    }

    /// @notice Reveal the answer and salt, then claim the prize if correct.
    /// @param answer Plain answer to the puzzle.
    /// @param salt Secret salt used in the commitment.
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

    /// @notice Compute the commitment expected from a participant.
    /// @param participant Address that will reveal.
    /// @param answer Plain answer to the puzzle.
    /// @param salt Secret salt.
    /// @return commitment Commitment hash.
    function commitmentFor(address participant, uint256 answer, bytes32 salt)
        public
        view
        returns (bytes32 commitment)
    {
        return keccak256(abi.encode(answer, salt, participant, address(this)));
    }
}
