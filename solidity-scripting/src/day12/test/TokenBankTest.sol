// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TokenBank} from "../TokenBank.sol";
import "../SosoToken2621.sol";

contract BankTest is Test {
    TokenBank public bank;
    SosoToken2621 public token;

    function setUp() public {
        token = new SosoToken2621("SosoToken2612", "STK");
        bank = new TokenBank(address(token));
    }
}
