// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

contract DeployTxOrigin is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployLabGovernance();
        _deployLabGovernanceFixed();
        vm.stopBroadcast();

        console2.log("LabGovernance", _readDeployment("LabGovernance"));
        console2.log("LabGovernanceFixed", _readDeployment("LabGovernanceFixed"));
    }
}
