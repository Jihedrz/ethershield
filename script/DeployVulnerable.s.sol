// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

/// @title DeployVulnerable
/// @notice Deploy every vulnerable lab contract on the local Anvil network.
contract DeployVulnerable is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployEtherVault();
        _deployShieldToken();
        _deployLabGovernance();
        _deploySignatureAirdrop();
        _deployFrontRunLottery();
        _deployRefundPool();
        _deployAdvancedTreasury();
        vm.stopBroadcast();

        console2.log("EtherVault", _readDeployment("EtherVault"));
        console2.log("ShieldToken", _readDeployment("ShieldToken"));
        console2.log("LabGovernance", _readDeployment("LabGovernance"));
        console2.log("SignatureAirdrop", _readDeployment("SignatureAirdrop"));
        console2.log("FrontRunLottery", _readDeployment("FrontRunLottery"));
        console2.log("RefundPool", _readDeployment("RefundPool"));
        console2.log("AdvancedTreasury", _readDeployment("AdvancedTreasury"));
    }
}
