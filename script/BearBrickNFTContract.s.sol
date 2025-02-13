// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/contract/BearBrickNFTContract.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract BearBrickNFTContractUUPS is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address owner = vm.envAddress("OWNER");
        

        address uupsProxy = Upgrades.deployUUPSProxy(
            "BearBrickNFTContract.sol",
            abi.encodeCall(
                BearBrickNFTContract.initialize,owner
            )
        );

        console.log("uupsProxy deploy at %s", uupsProxy);

        // contract upgrade
        // Upgrades.upgradeProxy(
        //     0x57aA394Cd408c1dB3E0De979e649e82BF8dD395F,
        //     "BearBrickNFTContract.sol",
        //     ""
        // );

        vm.stopBroadcast();
    }
}
