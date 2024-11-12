// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { AutomationCompatibleInterface } from './AutomationCompatibleInterface.sol';

contract ETHBank is AutomationCompatibleInterface {
    address admin;

    mapping(address => uint) internal balances;

    // add interval control
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    constructor(address _admin, uint256 refreshInterval) {
        admin = _admin;

        interval = refreshInterval;
        lastTimeStamp = block.timestamp;
    }

    // Receive ETH
    receive() external payable {
        // Call deposit function
        deposit();
    }

    // 提取函数：用户提取自己的 token，管理员可以提取所有 token
    function withdraw(uint256 amount) public {
        if (msg.sender == admin) {
            // 管理员提取所有的 token
            uint256 contractBalance = token.balanceOf(address(this));
            require(contractBalance > 0, 'No tokens to withdraw');

            bool success = token.transfer(admin, contractBalance);
            require(success, 'Admin withdraw failed');
        } else {
            // 普通用户提取自己存入的 token
            require(amount > 0, 'Amount must be greater than 0');
            require(balances[msg.sender] >= amount, 'Insufficient balance');

            // 更新用户余额
            balances[msg.sender] -= amount;

            // 转账给用户
            bool success = token.transfer(msg.sender, amount);
            require(success, 'User withdraw failed');
        }
    }

    function deposit(uint256 amount) public {
        // 将用户的 token 转移到 TokenBank 合约中
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, 'Token transfer failed');

        // 记录用户的存款
        balances[msg.sender] += amount;
    }

    // permit before deposit
    function permitDeposit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        tokenPermit.permit(msg.sender, address(this), amount, deadline, v, r, s);

        deposit(amount);
    }

    // chainlink Automation checkUpkeep
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        bool timePassed = (block.timestamp - lastTimeStamp) > interval;

        uint256 threshold = 0.0001 ether;
        bool balanceReachThreshold = address(this).balance > threshold;
        upkeepNeeded = timePassed && balanceReachThreshold;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;

        uint256 amountToTransfer = address(this).balance / 2;

        (bool success, ) = admin.call{ value: amountToTransfer }('');
        require(success, 'Failed to transfer to admin');
    }
}
