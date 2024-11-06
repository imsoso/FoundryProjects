// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {esRNT} from "../esRNT.sol";

contract MyESRNTTest is Test {}
/* 
// Contract to read
contract esRNT {
    struct LockInfo {
        address user; // 20 bytes
        uint64 startTime; // 8 bytes
        uint256 amount;// 32 bytes
    }
    LockInfo[] private _locks;

    constructor() {
        for (uint256 i = 0; i < 11; i++) {
        _locks.push(LockInfo(address(uint160(i+1)), uint64(block.timestamp * 2 - i), 1e18 * (i + 1)));
        }
    }
}
*/
