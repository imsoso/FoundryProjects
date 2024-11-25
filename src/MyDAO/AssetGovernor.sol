// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
先实现一个可以可计票的 Token
实现一个通过 DAO 管理Bank的资金使用：
Bank合约中有提取资金withdraw()，该方法仅管理员可调用。
治理 Gov 合约作为 Bank 管理员, Gov 合约使用 Token 投票来执行响应的动作。
通过发起提案从Bank合约资金，实现管理Bank的资金。
*/
import { Governor } from '@openzeppelin/contracts/governance/Governor.sol';
import { GovernorCountingSimple } from '@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol';
import { GovernorSettings } from '@openzeppelin/contracts/governance/extensions/GovernorSettings.sol';
import { GovernorTimelockControl } from '@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol';
import { GovernorVotes } from '@openzeppelin/contracts/governance/extensions/GovernorVotes.sol';
import { GovernorVotesQuorumFraction } from '@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol';
import { IVotes } from '@openzeppelin/contracts/governance/utils/IVotes.sol';
import { TimelockController } from '@openzeppelin/contracts/governance/TimelockController.sol';

contract AssetGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    constructor(
        IVotes _token,
        TimelockController _timelock
    )
        Governor('AssetGovernor')
        GovernorSettings(1 days, 1 weeks, 1e18)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256) {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
}
