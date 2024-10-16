// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    address constant admin = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        require(msg.sender == admin, "ONLY_ADMIN");
        number++;
    }
}
