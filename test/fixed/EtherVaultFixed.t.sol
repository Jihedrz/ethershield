// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { EtherVaultFixed } from "../../src/fixed/EtherVaultFixed.sol";

contract EtherVaultFixedHandler is Test {
    receive() external payable { }

    EtherVaultFixed public immutable vault;
    address[] public actors;
    uint256 public ghostSum;
    mapping(address => uint256) public ghostBalances;

    constructor(EtherVaultFixed vaultAddress) {
        vault = vaultAddress;
        actors.push(address(0xA1));
        actors.push(address(0xA2));
        actors.push(address(0xA3));
    }

    function deposit(uint256 actorSeed, uint256 amount) external {
        address actor = actors[bound(actorSeed, 0, actors.length - 1)];
        amount = bound(amount, 1, 10 ether);
        vm.deal(actor, amount);
        vm.prank(actor);
        vault.deposit{ value: amount }();
        ghostBalances[actor] += amount;
        ghostSum += amount;
    }

    function withdraw(uint256 actorSeed) external {
        address actor = actors[bound(actorSeed, 0, actors.length - 1)];
        uint256 amount = vault.balances(actor);
        if (amount == 0) {
            return;
        }
        vm.prank(actor);
        vault.withdraw();
        ghostBalances[actor] = 0;
        ghostSum -= amount;
    }
}

contract EtherVaultFixedTest is Test {
    receive() external payable { }

    EtherVaultFixed internal vault;

    function setUp() public {
        vault = new EtherVaultFixed();
    }

    function test_DepositAndWithdraw() public {
        vm.deal(address(this), 1 ether);
        vault.deposit{ value: 1 ether }();
        assertEq(vault.balances(address(this)), 1 ether);
        assertEq(vault.totalDeposits(), 1 ether);

        vault.withdraw();
        assertEq(vault.balances(address(this)), 0);
        assertEq(vault.totalDeposits(), 0);
        assertEq(address(vault).balance, 0);
    }

    function testFuzz_DepositWithdrawRoundTrip(uint96 rawAmount) public {
        uint256 amount = bound(uint256(rawAmount), 1, 100 ether);
        vm.deal(address(this), amount);

        vault.deposit{ value: amount }();
        assertEq(vault.balances(address(this)), amount);
        assertEq(vault.totalDeposits(), amount);

        vault.withdraw();
        assertEq(vault.balances(address(this)), 0);
        assertEq(vault.totalDeposits(), 0);
        assertEq(address(vault).balance, 0);
    }

    function test_RevertWhen_WithdrawWithoutDeposit() public {
        vm.expectRevert("EtherVaultFixed: nothing to withdraw");
        vault.withdraw();
    }
}

contract EtherVaultFixedInvariantTest is Test {
    EtherVaultFixed internal vault;
    EtherVaultFixedHandler internal handler;

    function setUp() public {
        vault = new EtherVaultFixed();
        handler = new EtherVaultFixedHandler(vault);
        targetContract(address(handler));
    }

    function invariant_VaultBalanceCoversRecordedBalances() public view {
        assertGe(address(vault).balance, handler.ghostSum());
    }

    function invariant_TotalDepositsMatchesGhostSum() public view {
        assertEq(vault.totalDeposits(), handler.ghostSum());
    }
}
