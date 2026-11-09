// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";
import { EtherShieldScript } from "./EtherShieldScript.sol";

contract DeploySignatureReplay is EtherShieldScript {
    function run() external {
        vm.startBroadcast(DEPLOYER_PK);
        _deploySignatureAirdrop();
        _deploySignatureAirdropFixed();
        vm.stopBroadcast();

        console2.log("SignatureAirdrop", _readDeployment("SignatureAirdrop"));
        console2.log("SignatureAirdropFixed", _readDeployment("SignatureAirdropFixed"));
    }
}
