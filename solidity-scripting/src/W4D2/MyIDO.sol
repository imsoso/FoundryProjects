// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
编写 IDO 合约，实现 Token 预售，需要实现如下功能：

开启预售: 支持对给定的任意ERC20开启预售，设定预售价格，募集ETH目标，超募上限，预售时长。
任意用户可支付ETH参与预售；
预售结束后，如果没有达到募集目标，则用户可领会退款；
预售成功，用户可领取 Token，且项目方可提现募集的ETH；
提交要求

编写 IDO 合约 和对应的测试合约
截图 foundry test 测试执行结果
提供 github IDO合约源码链接
*/
contract MyIDO {
    address public owner;

    mapping(address => uint256) public balances; // user address -> balance
    ERC20 public token;
    uint256 preSalePrice; // Token price in ETH
    uint256 minFunding; // Fundraising target in ETH
    uint256 maxFunding; // Maximum fundraising amount in ETH
    uint256 public currentTotalFunding;
    uint256 totalSupply;

    uint256 deploymentTimestamp; // Use to record contract deployment time
    uint256 preSaleDuration; // Campaign duration in seconds
    
    constructor(ERC20 _token, uint256 _preSalePrice, uint256 _minFunding, uint256 _maxFunding, uint256 _preSaleDuration, uint256 _totalSupply) {
        owner = msg.sender;
        token = _token;
        preSalePrice = _preSalePrice;
        minFunding = _minFunding;
        maxFunding = _maxFunding;
        deploymentTimestamp = block.timestamp;
        preSaleDuration = _preSaleDuration;
        totalSupply = _totalSupply;
    }

    modifier onlyActive {
        require(block.timestamp < deploymentTimestamp + preSaleDuration, "Project has ended");
        require(currentTotalFunding + msg.value < maxFunding, "Funding limit reached");
        _;
    }

    modifier onlySuccess {
        require(currentTotalFunding >= minFunding, "Funding target not reached");
        _;
    }

    modifier onlyFailed {
        require(currentTotalFunding < minFunding, "Cannot do it, Funding target reached");
        _;
    }

    // Contribute to a campaign for presale
    function contribute() public onlyActive payable {
        require(msg.value > preSalePrice, "Minimum contribution amount not met");
        currentTotalFunding += msg.value;
        balances[msg.sender] += msg.value;

        uint256 targetLeft = minFunding - currentTotalFunding;
        emit Contribution(msg.sender, msg.value,targetLeft);
    }

    function claimTokens() public onlySuccess {
        uint256 tokenAmount = totalSupply * balances[msg.sender] / currentTotalFunding;
        balances[msg.sender] = 0;
        token.transfer(msg.sender, tokenAmount);

        emit TokenClaim(msg.sender, token, tokenAmount);
    }

    function refund() public onlyFailed {
        require(balances[msg.sender] > 0, "User has no contributions");
        (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(sent, "Failed to send Ether");
        balances[msg.sender] = 0;

        emit Refund(msg.sender, balances[msg.sender]);
    }

    function teamWithdrawFunds() public onlySuccess() {
        require(owner == msg.sender, "Only the project owner can withdraw funds");
        uint256 totalETH = address(this).balance;
        uint256 ETHForTeam = totalETH / 10;
        (bool sent, ) = owner.call{value: ETHForTeam}("");
        require(sent, "Failed to send Ether");

        emit TeamWithdrawFunds(msg.sender, ETHForTeam);
    }
    // Event emitted when a user contributes to a campaign
    event Contribution(address indexed user, uint256 amount, uint256 amountLeft);
    // Event emitted when a user claims their tokens
    event TokenClaim(address indexed user, ERC20 token, uint256 amount);

    event Refund(address indexed user, uint256 amount);
    event TeamWithdrawFunds(address indexed user, uint256 amount);
}
