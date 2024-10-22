// SPDX-License-Identifier: MIT
/*
实现⼀个简单的多签合约钱包，合约包含的功能：

1、创建多签钱包时，确定所有的多签持有⼈和签名门槛
2、多签持有⼈可提交提案
3、其他多签⼈确认提案（使⽤交易的⽅式确认即可）
4、达到多签⻔槛、任何⼈都可以执⾏交易
*/
pragma solidity ^0.8.20;

error InvalidConstructParameters();

contract MultiSignatureWallet {
    mapping(address => bool) public canSign;

    uint256 public proposalNumber;

    event NewSignerAdded(address signer);

    enum ProposalType {
        Execute,
        AddSigner,
        RemoveSigner
    }

    struct Proposal {
        address to;
        uint256 value;
        bytes data;
        uint256 approvals;
        mapping(address => bool) isApproved;
        ProposalType proposalType;
        bool isExecuted;
        address operatedSigner; // signer who is removed or added
    }

    event ProposalInitiate(
        uint256 indexed proposalID,
        address to,
        uint256 value,
        bytes data,
        ProposalType proposalType,
        address operatedSigner
    );

    mapping(uint256 => Proposal) public proposals;

    constructor(address[] memory _allSigners, uint256 _requiredApprovals) {
        if (
            _allSigners.length < _requiredApprovals ||
            _requiredApprovals == 0 ||
            _allSigners.length == 0
        ) {
            revert InvalidConstructParameters();
        }

        for (uint256 i = 0; i < _allSigners.length; i++) {
            canSign[_allSigners[i]] = true;
            emit NewSignerAdded(_allSigners[i]);
        }
    }

    function initiateProposal(
        address to,
        uint256 value,
        bytes memory data,
        ProposalType proposalType,
        address operatedSigner
    ) external {
        uint256 proposalID = proposalNumber++;
        Proposal storage proposal = proposals[proposalID];
        proposal.to = to;
        proposal.value = value;
        proposal.data = data;
        proposal.proposalType = proposalType;
        proposal.operatedSigner = operatedSigner;

        emit ProposalInitiate(
            proposalID,
            to,
            value,
            data,
            proposalType,
            operatedSigner
        );
    }
}
