// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
编写一个 Bank 存款合约，实现功能：
1. 可以通过 Metamask 等钱包直接给 Bank 合约地址存款
2. 在 Bank 合约里记录了每个地址的存款金额
3. 使用可迭代的链表保存存款金额的前 10 名用户
*/
contract BankMappingList {
    event Deposit(address indexed sender, uint256 amount);

    mapping(address => uint) public balances;

    mapping(address => address) _nextDepositor;
    uint public depositorCount;
    address constant GUARD = address(1);

    constructor() {
        _nextDepositor[GUARD] = GUARD;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _isPreviousDepositor(
        address depositor,
        address previousDepositor
    ) internal view returns (bool) {
        return _nextDepositor[previousDepositor] == depositor;
    }

    function _verifyOrder(
        address prevDepositor,
        uint256 newValue,
        address nextDepositor
    ) internal view {
        return
            (prevDepositor == GUARD || balances[prevDepositor] >= newValue) &&
            (nextDepositor == GUARD || newValue >= balances[nextDepositor]);
    }

    function addDepositor(address depositor) public {
        require(!existDepositor(depositor), "Depositor already exists");

        _nextDepositor[depositor] = _nextDepositor[GUARD];
        _nextDepositor[GUARD] = depositor;
        depositorCount++;
    }
}