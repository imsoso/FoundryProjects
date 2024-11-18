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

    uint256 public constant REWARD_PER_BLOCK = 10 ether; // 10 RNT per block
    uint256 public lastRewardBlock; // The block number of the last reward
    uint256 public totalStakeWeight; // The total weight of all staked

    struct StakeInfo {
        uint256 staked;
        uint256 unclaimed;
        uint256 lastUpdateTime;
    }
    mapping(address => StakeInfo) public stakeInfos;
    address[] stakedUsers;

    constructor(address _esRNTToken, address _RNTToken) {
        esRNTToken = esRNT(_esRNTToken);
        RNTToken = RNT(_RNTToken);
        lastRewardBlock = block.number; // Set the last reward block to the current block
    }

    // User can stake their RNT to get rewards
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        stakeInfos[msg.sender].unclaimed += getRewardAmount(msg.sender);
        // Stacked must calculate after getRewardAmount is called 
        if (stakeInfos[msg.sender].lastUpdateTime == 0) {
            stakedUsers.push(msg.sender);
        }
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

    function updateRewardAmount() public {
        // Calcuate total rewards from last block
        uint256 multiplier = block.number - lastRewardBlock;
        uint256 totalReward = REWARD_PER_BLOCK * multiplier;

        uint256 pendingRewards = 0;
        for (uint256 i = 0; i < stakedUsers.length; i++) {
            address user = stakedUsers[i];
            pendingRewards = (stakeInfos[user].staked / totalStakeWeight) * totalReward;
            stakeInfos[user].unclaimed += pendingRewards;
        }
    }

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
