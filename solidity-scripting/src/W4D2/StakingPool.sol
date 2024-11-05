// SPDX-License-Identifier: MIT
/*
编写一个质押挖矿合约，实现如下功能：

1、用户随时可以质押项目方代币 RNT(自定义的ERC20) ，开始赚取项目方Token(esRNT)；
2、可随时解押提取已质押的 RNT；
3、可随时领取esRNT奖励，每质押1个RNT每天可奖励 1 esRNT;
4、esRNT 是锁仓性的 RNT， 1 esRNT 在 30 天后可兑换 1 RNT，随时间线性释放，支持提前将 esRNT 兑换成 RNT，但锁定部分将被 burn 燃烧掉。

用户随时可以质押项目方代币RNT开始賺取项目方esRNT
可随时解押提取已质押的 RNT，
可随时领取 esRNT奖励，
每质押 1 RNT 每天可奖励 1 esRNT
esRNT 是锁仓性的RNT，
 1 eRNT 在 30 天后可兑换 1 RNT,随时间线性释放，支持提前将 esRNT 兑换成RNT，但锁定部分将被 burn燃烧掉。
*/
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./erRNT.sol";
import "./RNT.sol";

contract StakingPool {
    esRNT public esRNTToken;
    RNT public RNTToken;

    uint256 public constant REWARD_RATE = 1; // 1 RNT per day
    uint256 public constant LOCK_PERIOD = 30 days;

    struct StakeInfo {
        uint256 staked;
        uint256 unclaimed;
        uint256 lastUpdateTime;
    }
    mapping(address => StakeInfo) public stakeInfos;


    constructor(address _esRNTToken, address _RNTToken) {
        esRNTToken = esRNT(_esRNTToken);
        RNTToken = RNT(_RNTToken);
    }

    // User can stake their RNT to get rewards
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        stakeInfos[msg.sender].unclaimed += getRewardAmount(msg.sender);
        // Stacked must calculate after getRewardAmount is called 
        // because it base on the old staked amount
        stakeInfos[msg.sender].staked += amount;
        stakeInfos[msg.sender].lastUpdateTime = block.timestamp;
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        stakedBalances[msg.sender] -= amount;
        RNTToken.transfer(msg.sender, amount);
    }

    function claim() external {
        uint256 reward = rewardBalances[msg.sender];
        require(reward > 0, "No reward to claim");
        rewardBalances[msg.sender] = 0;
        esRNTToken.mint(msg.sender, reward);
    }
    
    // calculate the reward amount for the user
    // user | Staked | Unclaimed| Lastupdatetime|Action
    // Alice|10|0|10:00|Stake
    // Alice|10 + 20 | 0 + 10 * 1/24 = 0.41|11:00|Stake
    // Alice|10 + 20 + 10 | 0.41 + 30 * 2/24 = 2.91|13:00|Stake
    // Alice|10 + 20 + 10 -15 | 2.91 +40* 2/24 = 6.24|15:00|UnStake
    // Alice|10 + 20 + 10 -15 | 0|16:00|Claim
    function getRewardAmount(address user) public view returns (uint256) {
        uint256 pendingRewards = (stakeInfos[user].staked  * (block.timestamp - stakeInfos[user].lastupdateTime)) / DAY_IN_SECONDS;
        return pendingRewards;
    }
}
