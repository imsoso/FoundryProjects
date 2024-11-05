// SPDX-License-Identifier: MIT
/*
编写一个质押挖矿合约，实现如下功能：

1、用户随时可以质押项目方代币 RNT(自定义的ERC20) ，开始赚取项目方Token(esRNT)；
2、可随时解押提取已质押的 RNT；
3、可随时领取esRNT奖励，每质押1个RNT每天可奖励 1 esRNT;
4、esRNT 是锁仓性的 RNT， 1 esRNT 在 30 天后可兑换 1 RNT，随时间线性释放，支持提前将 esRNT 兑换成 RNT，但锁定部分将被 burn 燃烧掉。
*/
pragma solidity >=0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract esRNT is ERC20Burnable {
    // RNT token
    IERC20 public stakingToken;
    // lock period
    uint256 public lockPeriod;

    struct LockInfo {
        uint256 amount;
        uint256 lockTime;
    }
    mapping(address => LockInfo[]) public lockInfos;
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10 * 1e18);
    }

    function mint(address to, uint256 amount) external {        
        _mint(to, amount);
        lockInfos[to].push(LockInfo({ amount: amount, lockTime: block.timestamp }));
        emit TokenLocked(to, amount, block.timestamp);
    }

    
  // redeem esRNT to RNT
    function redeem(uint256 lockAmount) external {
        LockInfo[] storage userLocks = lockInfos[msg.sender];
        if (lockAmount >= userLocks.length) revert InvalidLockAmount();

        LockInfo storage lock = userLocks[lockAmount];
        uint256 lockedAmount = lock.amount;
        if (lockedAmount == 0) revert NoTokenLocked();

        uint256 timePassed;
        unchecked {
            // timestamp will not overflow
            timePassed = block.timestamp - lock.lockTime;
        }

        uint256 unlockedAmount;
        // if lock period is passed, unlock all
        if (timePassed >= lockPeriod) {
            unlockedAmount = lockedAmount;
        } else {
            // if lock period is not passed, unlock partially
            unchecked {
                // since timePassed < lockPeriod, it will not overflow
                unlockedAmount = (lockedAmount * timePassed) / lockPeriod;
            }
        }

        // burn esRNT
        _burn(msg.sender, lockedAmount);

        // transfer RNT to user
        _transfer(address(stakingToken), msg.sender, unlockedAmount);

        // clear lock info
        lock.amount = 0;

        emit TokenRedeemed(msg.sender, lockedAmount, unlockedAmount);
    }

    // custom errors
    error InvalidLockAmount();
    error NoTokenLocked();

    // events
    event TokenLocked(address indexed user, uint256 amount, uint256 lockTime);
    event TokenRedeemed(address indexed user, uint256 amount, uint256 receivedAmount);

}