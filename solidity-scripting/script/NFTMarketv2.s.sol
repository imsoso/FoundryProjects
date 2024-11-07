// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/W4D4/NFTMarketV2.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTMarketScript is Script {
    function run() public broadcaster {
        Options memory opts;
        opts.unsafeSkipAllChecks = true;
        opts.referenceContract = "Counter.sol";
        // proxy: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
        Upgrades.upgradeProxy(
            0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512,
            "NFTMarketv2.sol",
            "",
            opts
        );
    }
}
