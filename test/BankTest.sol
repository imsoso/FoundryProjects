// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;
/*
为银行合约的 DepositETH 方法编写测试 Case，检查以下内容：
断言检查 Deposit 事件输出是否符合预期。
断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
*/
import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract  BankTest is Test {
     Bank public bank;
    
    function setUp() public {
        bank = new Bank();
    }
}
