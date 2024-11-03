// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    mapping(address => uint256) public balances; // user address -> balance

    IERC20 public token;
    uint256 preSalePrice; // Token price in ETH
    uint256 minFunding; // Fundraising target in ETH
    uint256 maxFunding; // Maximum fundraising amount in ETH
    uint256 currentTotalFunding;
    uint256 totalSupply;

    uint256 deploymentTimestamp; // Use to record contract deployment time
    uint256 preSaleDuration; // Campaign duration in seconds
    
    constructor(IERC20 _token, uint256 _preSalePrice, uint256 _minFunding, uint256 _maxFunding, uint256 _preSaleDuration, uint256 _totalSupply) {
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

    // Event emitted when a user contributes to a campaign
    event Contribution(address indexed user, uint256 amount, uint256 amountLeft);
    // Event emitted when a user claims their tokens
    event TokenClaim(address indexed user, IERC20 token, uint256 amount);
}
