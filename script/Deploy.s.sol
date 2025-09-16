// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {WUSDT} from "../src/WUSDT.sol";
import {VideoPlatformFactory} from "../src/VideoPlatformFactory.sol";

contract DeployScript is Script {
    function run() public {
        console.log("Starting deployment to Base Testnet...");
        console.log("");

        // Load deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Network: Base Testnet");
        console.log("Chain ID: 84532");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy WUSDT contract
        console.log("Deploying WUSDT contract...");
        WUSDT wusdt = new WUSDT();
        console.log("WUSDT contract deployed at:", address(wusdt));

        // 2. Deploy VideoPlatformFactory contract with the WUSDT address
        console.log("Deploying VideoPlatformFactory contract...");
        VideoPlatformFactory videoPlatformFactory = new VideoPlatformFactory(
            address(wusdt)
        );
        console.log(
            "VideoPlatformFactory contract deployed at:",
            address(videoPlatformFactory)
        );

        vm.stopBroadcast();

        console.log("");
        console.log("Deployment complete!");
    }
}