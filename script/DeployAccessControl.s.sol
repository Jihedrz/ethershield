// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

/// @title DeployAccessControl
/// @notice Deploy the vulnerable token and its corrected version.
contract DeployAccessControl is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployShieldToken();
        _deployShieldTokenFixed();
        vm.stopBroadcast();

        console2.log("ShieldToken", _readDeployment("ShieldToken"));
        console2.log("ShieldTokenFixed", _readDeployment("ShieldTokenFixed"));
    }
}
