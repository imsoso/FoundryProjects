// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/W4D4/NFTMarketV1.sol";
import {NFTMarketV2} from "../src/W4D4/NFTMarketV2.sol";;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTMarketScript is Script {
    function run() public {
        Options memory opts;
        opts.unsafeSkipAllChecks = true;
        opts.referenceContract = "NFTMarketV1.sol";

        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        address aNFTMarketV1 = address(new NFTMarketV1());

        address proxyAddress = Upgrades.deployTransparentProxy(
            "NFTMarketV1.sol",
            deployer,
            "",
            opts
        );

        address NFTMarketV1Addr = Upgrades.getImplementationAddress(
            proxyAddress
        );
        Upgrades.upgradeProxy(proxyAddress, "NFTMarketV2.sol", abi.encodeCall(NFTMarketV2.initialize,(deployer)), opts);
        address NFTMarketV2Addr = Upgrades.getImplementationAddress(
            proxyAddress
        );

        vm.stopBroadcast();

        console.log("deployer:", deployer);
        console.log("proxy addr:", proxyAddress);
        console.log("v1 addr:", aNFTMarketV1);
        console.log(
            "v2 addr:",
            Upgrades.getImplementationAddress(proxyAddress)
        );
    }
}
