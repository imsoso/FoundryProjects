// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from 'forge-std/Test.sol';
import { TokenBank } from '../src/MyBank/TokenBank.sol';
import { PollToken } from '../src/MyToken/PollToken.sol';
import { AssetGovernor } from '../src/MyDAO/AssetGovernor.sol';
import { TimelockController } from '@openzeppelin/contracts/governance/TimelockController.sol';

/*
先实现一个可以可计票的 Token
实现一个通过 DAO 管理Bank的资金使用：
Bank合约中有提取资金withdraw()，该方法仅管理员可调用。
治理 Gov 合约作为 Bank 管理员, Gov 合约使用 Token 投票来执行响应的动作。
通过发起提案从Bank合约资金，实现管理Bank的资金。
*/

enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
}

contract MyDAOTest is Test {
    PollToken token;
    TokenBank tokenBank;
    AssetGovernor gov;

    address voter1;
    address voter2;
    address executor;

    uint256 public constant VOTING_DELAY = 1;
    uint256 public constant VOTING_PERIOD = 50_400;

    uint8 constant I_VOTE_YES = 1;

    function setUp() public {
        token = new PollToken(address(this));
        gov = new AssetGovernor(token, 'MyDAO');
        tokenBank = new TokenBank(address(gov));

        voter1 = makeAddr('voter1');
        voter2 = makeAddr('voter2');
        executor = makeAddr('executor');

        token.transfer(voter1, 100_000 * 10 ** 18);
        token.transfer(voter2, 100_000 * 10 ** 18);

        vm.deal(address(tokenBank), 10 ether);
    }

    function testVoteToWithdraw() public {
        // delegate voting power to self
        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        // create a proposal
        vm.prank(voter1);
        uint256 proposalId = gov.proposeBankWithdrawal(address(tokenBank), executor, 1 ether, 'Send 1 ETH to executor');
        console.log('State1 is:', uint256(gov.state(proposalId)));

        // wait for voting delay
        vm.roll(block.number + VOTING_DELAY + 10);
        console.log('State2 is:', uint256(gov.state(proposalId)));

        // start voting
        vm.prank(voter1);
        gov.castVote(proposalId, I_VOTE_YES);

        vm.prank(voter2);
        gov.castVote(proposalId, I_VOTE_YES);

        vm.roll(block.number + VOTING_PERIOD + 1);

        // check proposal state
        console.log('State3 is:', uint256(gov.state(proposalId)));

        bytes memory callData = abi.encodeWithSignature('withdraw(address,uint256)', executor, 1 ether);
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(tokenBank);
        values[0] = 0;
        calldatas[0] = callData;

        vm.prank(voter1);
        gov.execute(targets, values, calldatas, keccak256(bytes('Send 1 ETH to executor')));

        // check result
        assertEq(address(tokenBank).balance, 9 ether);
        assertEq(executor.balance, 1 ether);
    }
}
