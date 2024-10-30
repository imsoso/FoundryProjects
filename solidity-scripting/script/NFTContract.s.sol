// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {Script} from "forge-std/Script.sol";
import {SosoNFT} from "../src/day12/NFTToken.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SosoNFT nftContract = new SosoNFT();

        vm.stopBroadcast();
    }
}
