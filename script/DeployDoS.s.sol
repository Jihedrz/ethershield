// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

contract DeployDoS is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployRefundPool();
        _deployRefundPoolFixed();
        vm.stopBroadcast();

        console2.log("RefundPool", _readDeployment("RefundPool"));
        console2.log("RefundPoolFixed", _readDeployment("RefundPoolFixed"));
    }
}
