//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/MetaMultisigWallet.sol";
import "./DeployHelpers.s.sol";

contract DeployMetaMultisigWallet is ScaffoldETHDeploy {
    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        vm.startBroadcast(deployerPrivateKey);

        address[] memory owners = new address[](1);
        owners[0] = 0xb649caCf58212Cd17D058999e10784AE71B88113;
        uint256 requiredSigners = 1;

        MetaMultisigWallet multisig = new MetaMultisigWallet(owners, requiredSigners);
        console.logString(string.concat("YourContract deployed at: ", vm.toString(address(multisig))));
        (bool success,) = address(multisig).call{ value: 200000000000000000 }("");
        if (!success) {
            revert("DEPLOY: Error on transfer balance");
        }

        vm.stopBroadcast();
    }
}
