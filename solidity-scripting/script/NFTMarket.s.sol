// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/day12/NFTMarket.sol";

contract NFTMarketScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address tokenAddress = 0x4c65bDEA9e905992731d5727F7Fe86EaD464518C;
        address nftAddress = 0x68AAaf6908F070b6ef06a486ca5838fe63E0Ca97;

        NFTMarket market = new NFTMarket(nftAddress, tokenAddress);

        console.log("NFTMarket deployed at:", address(market));

        vm.stopBroadcast();
    }
}
