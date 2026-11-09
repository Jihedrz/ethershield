// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

contract DeployAdvanced is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployAdvancedTreasury();
        _deployAdvancedTreasuryFixed();
        vm.stopBroadcast();

        console2.log("AdvancedTreasury", _readDeployment("AdvancedTreasury"));
        console2.log("AdvancedTreasuryFixed", _readDeployment("AdvancedTreasuryFixed"));
    }
}
