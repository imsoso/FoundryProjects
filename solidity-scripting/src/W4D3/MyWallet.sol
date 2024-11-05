// SPDX-License-Identifier: MIT
//重新修改 MyWallet 合约的 transferOwernship 和 auth 逻辑，使用内联汇编方式来 set和get owner 地址
pragma solidity >=0.8.20;

contract MyWallet {
    string public name;
    mapping (address => bool) private approved;
    address public owner;

    modifier auth {
        address currentOwner;
        assembly {
            currentOwner := sload(0)
        }
        require(msg.sender == currentOwner,"Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        
        assembly {
            sstore(0, caller())
        }
    }

    function transferOwnership(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");
        assembly {
            sstore(0, _addr)
        }
    }
}