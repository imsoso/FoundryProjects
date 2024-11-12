// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import 'forge-std/Script.sol';
import 'forge-std/console2.sol';
import '../EthBank.sol';
import '@openzeppelin/contracts/utils/Create2.sol';

contract DeployScript is Script {
    bytes32 constant SALT = bytes32(uint256(0x0000000000000000000000000000000000000000d4bf2663da51c10215000003));
    function run() public {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        ETHBank newBank = new ETHBank{ salt: SALT }(deployerAddress, 10);
        console2.log('Bank deployed to:', address(newBank));
        console2.log('Deployed by:', deployerAddress);

        vm.stopBroadcast();
    }

    // The contract can receive ether to enable `payable` constructor calls if needed.
    receive() external payable {}
}
