// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

contract DeployReentrancy is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployEtherVault();
        _deployEtherVaultFixed();
        vm.stopBroadcast();

        console2.log("EtherVault", _readDeployment("EtherVault"));
        console2.log("EtherVaultFixed", _readDeployment("EtherVaultFixed"));
    }
}
