// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AdminTokenBank.sol";

contract DeployAdminTokenBankScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address tokenAddress = 0x4c65bDEA9e905992731d5727F7Fe86EaD464518C;
        address adminAddress = 0x2e04aF48d11F4E505F09e253B119BfDa6772df54;

        AdminTokenBank bank = new AdminTokenBank(adminAddress, tokenAddress);

        console.log("AdminTokenBank deployed at:", address(bank));

        vm.stopBroadcast();
    }
}
