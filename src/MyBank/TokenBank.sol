// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
先实现一个可以可计票的 Token
实现一个通过 DAO 管理Bank的资金使用：
Bank合约中有提取资金withdraw()，该方法仅管理员可调用。
治理 Gov 合约作为 Bank 管理员, Gov 合约使用 Token 投票来执行响应的动作。
通过发起提案从Bank合约资金，实现管理Bank的资金。
*/
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract TokenBank is Ownable {
    error InsufficientBalance();

    event Withdrawal(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // only owner(Governor) can withdraw
    function withdraw(address to, uint256 amount) external onlyOwner {
        if (address(this).balance < amount) revert InsufficientBalance();
        Address.sendValue(payable(to), amount);
        emit Withdrawal(to, amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
