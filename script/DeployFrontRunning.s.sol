// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

contract DeployFrontRunning is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deployFrontRunLottery();
        _deployCommitRevealLottery();
        vm.stopBroadcast();

        console2.log("FrontRunLottery", _readDeployment("FrontRunLottery"));
        console2.log("CommitRevealLottery", _readDeployment("CommitRevealLottery"));
    }
}
