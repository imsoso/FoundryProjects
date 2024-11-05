// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract esRNT {
    struct LockInfo {
        address user;
        uint64 startTime;
        uint256 amount;
    }
    LockInfo[] private _locks;

    constructor() {
        for (uint256 i = 0; i < 11; i++) {
        _locks.push(LockInfo(address(uint160(i+1)), uint64(block.timestamp * 2 - i), 1e18 * (i + 1)));
        }
    }
}