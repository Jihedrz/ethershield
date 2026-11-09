// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

contract DeployFixed is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployEtherVaultFixed();
        _deployShieldTokenFixed();
        _deployLabGovernanceFixed();
        _deploySignatureAirdropFixed();
        _deployCommitRevealLottery();
        _deployRefundPoolFixed();
        _deployAdvancedTreasuryFixed();
        vm.stopBroadcast();

        console2.log("EtherVaultFixed", _readDeployment("EtherVaultFixed"));
        console2.log("ShieldTokenFixed", _readDeployment("ShieldTokenFixed"));
        console2.log("LabGovernanceFixed", _readDeployment("LabGovernanceFixed"));
        console2.log("SignatureAirdropFixed", _readDeployment("SignatureAirdropFixed"));
        console2.log("CommitRevealLottery", _readDeployment("CommitRevealLottery"));
        console2.log("RefundPoolFixed", _readDeployment("RefundPoolFixed"));
        console2.log("AdvancedTreasuryFixed", _readDeployment("AdvancedTreasuryFixed"));
    }
}
