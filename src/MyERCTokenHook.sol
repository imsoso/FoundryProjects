// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./MyERCToken.sol";
/* 
扩展 ERC20 合约 ，添加一个有hook 功能的转账函数，如函数名为：transferWithCallback ，在转账时，如果目标地址是合约地址的话，调用目标地址的 tokensReceived() 方法。

继承 TokenBank 编写 TokenBankV2，支持存入扩展的 ERC20 Token，用户可以直接调用 transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中。

（备注：TokenBankV2 需要实现 tokensReceived 来实现存款记录工作）
*/

contract MyERCTokenHook is BaseERC20 {
    function transferWithCallback(address _to, uint256 _value) public {
        // 目标地址是合约地址
        if (_to == address(this)) {
            require(_to != address(0), "ERC20: transfer to the zero address");
            // 调用目标合约的 tokensReceived() 方法
            (bool success, ) = _to.call(
                abi.encodeWithSignature("tokensReceived(uint256)", _value)
            );

            require(success, "ERC20: transfer failed");
        } else {
            super.transfer(_to, _value);
        }
    }
}
