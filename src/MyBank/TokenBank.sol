// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
先实现一个可以可计票的 Token
实现一个通过 DAO 管理Bank的资金使用：
Bank合约中有提取资金withdraw()，该方法仅管理员可调用。
治理 Gov 合约作为 Bank 管理员, Gov 合约使用 Token 投票来执行响应的动作。
通过发起提案从Bank合约资金，实现管理Bank的资金。
*/
import '../MyToken/PollToken.sol';

contract TokenBank {
    address admin;
    PollToken public token;

    mapping(address => uint) internal balances;

    event OwnerTransfered(address indexed oldOwner, address indexed newOwner);

    constructor(PollToken _token) {
        admin = msg.sender;
        token = _token;
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == admin, 'Only admin can withdraw');
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, 'No tokens to withdraw');

        bool success = token.transfer(admin, contractBalance);
        require(success, 'Admin withdraw failed');
    }

    modifier onlyOwner() {
        require(msg.sender == admin, 'Only owner can call this function');
        _;
    }

    function transferOwner(address newAdmin) external onlyOwner {
        address oldAdmin = admin;
        admin = newAdmin;
        emit OwnerTransfered(oldAdmin, newAdmin);
    }
}
