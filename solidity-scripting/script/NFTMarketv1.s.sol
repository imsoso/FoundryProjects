// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/W4D4/NFTMarketV1.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTMarketScript is Script {
    function run() public broadcaster {
        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        address proxy = Upgrades.deployTransparentProxy(
            "NFTMarketV1.sol",
            deployer, // INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN,
            "", // abi.encodeCall(MyContract.initialize, ("arguments for the initialize function")
            opts
        );

        saveContract("local", "Counter", proxy);

        console.log("Counter deployed on %s", address(proxy));

        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(deployerPrivateKey);

        // NFTMarketV1 market = new NFTMarketV1();

        // console.log("NFTMarket deployed at:", address(market));

        // vm.stopBroadcast();
    }
}
