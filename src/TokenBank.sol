// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。

TokenBank 有两个方法：

deposit() : 需要记录每个地址的存入数量；
withdraw（）: 用户可以提取自己的之前存入的 token，管理员可以提取所有的token。
*/
import "./MyERCToken.sol";

contract TokenBank {
    address admin;
    BaseERC20 public token;

    mapping(address => uint) internal balances;

    constructor(BaseERC20 _token) {
        admin = msg.sender;
        token = _token;
    }

    // 提取函数：用户提取自己的 token，管理员可以提取所有 token
    function withdraw(uint256 amount) public {
        if (msg.sender == admin) {
            // 管理员提取所有的 token
            uint256 contractBalance = token.balanceOf(address(this));
            require(contractBalance > 0, "No tokens to withdraw");

            bool success = token.transfer(admin, contractBalance);
            require(success, "Admin withdraw failed");
        } else {
            // 普通用户提取自己存入的 token
            require(amount > 0, "Amount must be greater than 0");
            require(balances[msg.sender] >= amount, "Insufficient balance");

            // 更新用户余额
            balances[msg.sender] -= amount;

            // 转账给用户
            bool success = token.transfer(msg.sender, amount);
            require(success, "User withdraw failed");
        }
    }

    function deposit(uint256 amount) public {
        // 将用户的 token 转移到 TokenBank 合约中
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // 记录用户的存款
        balances[msg.sender] += amount;
    }
}
