// SPDX-License-Identifier: MIT
/*
编写 StakingPool 合约，实现 Stake 和 Unstake 方法
允许任何人质押ETH来赚钱 KK Token。
其中 KK Token 是每一个区块产出 10 个，产出的 KK Token 需要根据质押时长和质押数量来公平分配。
*/
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './erRNT.sol';
import './RNT.sol';

contract StakingPool {
    esRNT public esRNTToken;
    RNT public RNTToken;

    uint256 public constant REWARD_RATE = 1; // 1 RNT per day
    uint256 public constant LOCK_PERIOD = 30 days;
    uint256 public constant DAY_IN_SECONDS = 86400 ;

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
        require(stakeInfos[msg.sender].staked >= amount, "Insufficient staked balance");

        // We still calculate reward amount for the user
        // because time elapsed before unstake
        stakeInfos[msg.sender].unclaimed += getRewardAmount(msg.sender);
        // Stacked must calculate after getRewardAmount is called 
        // because it base on the old staked amount
        stakeInfos[msg.sender].staked -= amount;
        stakeInfos[msg.sender].lastUpdateTime = block.timestamp;
    }

    function claim() external {
        uint256 amount = stakeInfos[msg.sender].unclaimed;
        require(amount > 0, "No rewards to claim");
        
        RNTToken.transferFrom(msg.sender, address(this), amount);
        esRNTToken.mint(msg.sender, amount);
    }
    
    // calculate the reward amount for the user
    // user | Staked | Unclaimed| Lastupdatetime|Action
    // Alice|10|0|10:00|Stake
    // Alice|10 + 20 | 0 + 10 * 1/24 = 0.41|11:00|Stake
    // Alice|10 + 20 + 10 | 0.41 + 30 * 2/24 = 2.91|13:00|Stake
    // Alice|10 + 20 + 10 -15 | 2.91 +40* 2/24 = 6.24|15:00|UnStake
    // Alice|10 + 20 + 10 -15 | 0|16:00|Claim
    function getRewardAmount(address user) public view returns (uint256) {
        uint256 pendingRewards = (stakeInfos[user].staked  * (block.timestamp - stakeInfos[user].lastUpdateTime)) / DAY_IN_SECONDS;
        return pendingRewards;
    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256) {
        return stakeInfos[account].staked;
    }

    /**
     * @dev 获取待领取的 RNT Token 收益
     * @param account 质押账户
     * @return 待领取的 RNT Token 收益
     */
    function earned(address account) external view returns (uint256) {
        return stakeInfos[account].unclaimed;
    }
}
