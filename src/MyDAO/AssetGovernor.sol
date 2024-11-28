// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
先实现一个可以可计票的 Token
实现一个通过 DAO 管理Bank的资金使用：
Bank合约中有提取资金withdraw()，该方法仅管理员可调用。
治理 Gov 合约作为 Bank 管理员, Gov 合约使用 Token 投票来执行响应的动作。
通过发起提案从Bank合约资金，实现管理Bank的资金。
*/
import '@openzeppelin/contracts/governance/Governor.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorSettings.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorVotes.sol';
import '@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol';

contract AssetGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    constructor(
        IVotes _token,
        string memory _name
    )
        Governor(_name)
        GovernorSettings(
            1 /* 1 block voting delay */,
            50_400 /* 1 week voting period (assuming 12 sec block time) */,
            0 /* 0 vote threshold for proposals */
        )
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4) // 4% quorum
    {}

    // voting delay
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    // voting period
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    // quorum
    function quorum(uint256 blockNumber) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256) {
        return super.quorum(blockNumber);
    }

    // proposal threshold
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    // create a proposal to withdraw from bank
    function proposeBankWithdrawal(address bankAddress, address to, uint256 amount, string memory description) public returns (uint256) {
        bytes memory callData = abi.encodeWithSignature('withdraw(address,uint256)', to, amount);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = bankAddress;
        values[0] = 0;
        calldatas[0] = callData;

        return propose(targets, values, calldatas, description);
    }
}
