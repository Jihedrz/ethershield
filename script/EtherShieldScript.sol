// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { EtherVault } from "../src/vulnerable/EtherVault.sol";
import { ShieldToken } from "../src/vulnerable/ShieldToken.sol";
import { LabGovernance } from "../src/vulnerable/LabGovernance.sol";
import { SignatureAirdrop } from "../src/vulnerable/SignatureAirdrop.sol";
import { FrontRunLottery } from "../src/vulnerable/FrontRunLottery.sol";
import { RefundPool } from "../src/vulnerable/RefundPool.sol";
import { AdvancedTreasury } from "../src/vulnerable/AdvancedTreasury.sol";
import { EtherVaultFixed } from "../src/fixed/EtherVaultFixed.sol";
import { ShieldTokenFixed } from "../src/fixed/ShieldTokenFixed.sol";
import { LabGovernanceFixed } from "../src/fixed/LabGovernanceFixed.sol";
import { SignatureAirdropFixed } from "../src/fixed/SignatureAirdropFixed.sol";
import { CommitRevealLottery } from "../src/fixed/CommitRevealLottery.sol";
import { RefundPoolFixed } from "../src/fixed/RefundPoolFixed.sol";
import { AdvancedTreasuryFixed } from "../src/fixed/AdvancedTreasuryFixed.sol";

/// @title EtherShieldScript
/// @notice Shared deployment helpers and local Anvil test accounts.
/// @dev All keys below are the public default Anvil accounts. They are used only
///      on the local 127.0.0.1 network and must never be used on a real network.
abstract contract EtherShieldScript is Script {
    uint256 internal constant DEPLOYER_PK =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address internal constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 internal constant ATTACKER_PK =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    address internal constant ATTACKER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    uint256 internal constant VICTIM_PK =
        0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    address internal constant VICTIM = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    uint256 internal constant PUZZLE_ANSWER = 42;

    /// @notice Persist the address of a deployed contract for later scripts.
    function _writeDeployment(string memory name, address deployed) internal {
        string memory path = string.concat("deployments/", name, ".json");
        string memory json = vm.serializeAddress(name, "address", deployed);
        vm.writeJson(json, path);
    }

    /// @notice Load a previously persisted contract address.
    function _readDeployment(string memory name) internal view returns (address) {
        string memory path = string.concat("deployments/", name, ".json");
        return vm.parseJsonAddress(vm.readFile(path), ".address");
    }

    /// @notice Hash of the public lottery answer.
    function _puzzleHash() internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PUZZLE_ANSWER));
    }

    function _deployEtherVault() internal returns (EtherVault vault) {
        vault = new EtherVault();
        _writeDeployment("EtherVault", address(vault));
    }

    function _deployEtherVaultFixed() internal returns (EtherVaultFixed vault) {
        vault = new EtherVaultFixed();
        _writeDeployment("EtherVaultFixed", address(vault));
    }

    function _deployShieldToken() internal returns (ShieldToken token) {
        token = new ShieldToken(1_000_000 ether);
        _writeDeployment("ShieldToken", address(token));
    }

    function _deployShieldTokenFixed() internal returns (ShieldTokenFixed token) {
        token = new ShieldTokenFixed(1_000_000 ether);
        _writeDeployment("ShieldTokenFixed", address(token));
    }

    function _deployLabGovernance() internal returns (LabGovernance governance) {
        governance = new LabGovernance();
        _writeDeployment("LabGovernance", address(governance));
    }

    function _deployLabGovernanceFixed() internal returns (LabGovernanceFixed governance) {
        governance = new LabGovernanceFixed();
        _writeDeployment("LabGovernanceFixed", address(governance));
    }

    function _deploySignatureAirdrop() internal returns (SignatureAirdrop airdrop) {
        airdrop = new SignatureAirdrop(DEPLOYER);
        airdrop.fund{ value: 100 ether }();
        _writeDeployment("SignatureAirdrop", address(airdrop));
    }

    function _deploySignatureAirdropFixed() internal returns (SignatureAirdropFixed airdrop) {
        airdrop = new SignatureAirdropFixed(DEPLOYER);
        airdrop.fund{ value: 100 ether }();
        _writeDeployment("SignatureAirdropFixed", address(airdrop));
    }

    function _deployFrontRunLottery() internal returns (FrontRunLottery lottery) {
        lottery = new FrontRunLottery{ value: 10 ether }(_puzzleHash());
        _writeDeployment("FrontRunLottery", address(lottery));
    }

    function _deployCommitRevealLottery() internal returns (CommitRevealLottery lottery) {
        lottery = new CommitRevealLottery{ value: 10 ether }(_puzzleHash(), 1 days, 1 days);
        _writeDeployment("CommitRevealLottery", address(lottery));
    }

    function _deployRefundPool() internal returns (RefundPool pool) {
        pool = new RefundPool();
        _writeDeployment("RefundPool", address(pool));
    }

    function _deployRefundPoolFixed() internal returns (RefundPoolFixed pool) {
        pool = new RefundPoolFixed();
        _writeDeployment("RefundPoolFixed", address(pool));
    }

    function _deployAdvancedTreasury() internal returns (AdvancedTreasury treasury) {
        treasury = new AdvancedTreasury();
        _writeDeployment("AdvancedTreasury", address(treasury));
    }

    function _deployAdvancedTreasuryFixed() internal returns (AdvancedTreasuryFixed treasury) {
        treasury = new AdvancedTreasuryFixed();
        _writeDeployment("AdvancedTreasuryFixed", address(treasury));
    }
}
