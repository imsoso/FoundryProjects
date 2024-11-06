
## 作业1：
重新修改 MyWallet 合约的 transferOwernship 和 auth 逻辑，使用内联汇编方式来 set和get owner 地址
```solidity
contract MyWallet { 
    public string name;
    private mapping (address => bool) approved;
    public address owner;

    modifier auth {
        require (msg.sender == owner, "Not authorized");
        _;
    }

    constructor(string _name) {
        name = _name;
        owner = msg.sender;
    } 

    function transferOwernship(address _addr) auth {
        require(_addr!=address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");
        owner = _addr;
    }
}
```

答：
```solidity
contract MyWallet {
    string public name;
    mapping (address => bool) private approved;
    address public owner;

    modifier auth {
         require (msg.sender == owner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        assembly {
            sstore(2, caller())
        }
    }

    function transferOwnership(address _addr) external auth {
        require(_addr != address(0), "New owner is the zero address");
        
        address current_owner;
        assembly {
            current_owner := sload(2)
        }
        require(current_owner != _addr, "New owner is the same as the old owner");

        assembly {
            sstore(2, _addr)
        }
    }
}
```

## 作业2：
使用你熟悉的语言利用 eth_getStorageAt RPC API 从链上读取 _locks 数组中的所有元素值，或者从另一个合约中设法读取esRNT中私有数组 _locks 元素数据，并打印出如下内容：
locks[0]: user:…… ,startTime:……,amount:……

答：
- https://github.com/imsoso/FoundryProjects/blob/main/solidity-scripting/src/W4D3/test/esRNTTest.sol 

本地操作方法：
1、先用 Anvil 模拟结点出来
2、forge test --rpc-url http://127.0.0.1:8545 -vvv

`Logs:`
  `Lock 0`
  `User: 0x0000000000000000000000000000000000000001`
  `StartTime: 3461774140`

  `Amount: 1000000000000000000`
  ----------------

  `Lock 1`
  `User: 0x0000000000000000000000000000000000000002`
  `StartTime: 3461774139`

  `Amount: 2000000000000000000`
  ----------------

  `Lock 2`
  `User: 0x0000000000000000000000000000000000000003`
  `StartTime: 3461774138`

  `Amount: 3000000000000000000`
  ----------------

  `Lock 3`
  `User: 0x0000000000000000000000000000000000000004`
  `StartTime: 3461774137`

  `Amount: 4000000000000000000`
  ----------------

  `Lock 4`
  `User: 0x0000000000000000000000000000000000000005`
  `StartTime: 3461774136`

  `Amount: 5000000000000000000`
  ----------------

  `Lock 5`
  `User: 0x0000000000000000000000000000000000000006`
  `StartTime: 3461774135`

  `Amount: 6000000000000000000`
  ----------------

  `Lock 6`
  `User: 0x0000000000000000000000000000000000000007`
  `StartTime: 3461774134`

  `Amount: 7000000000000000000`
  ----------------

  `Lock 7`
  `User: 0x0000000000000000000000000000000000000008`
  `StartTime: 3461774133`

  `Amount: 8000000000000000000`
  ----------------

  `Lock 8`
  `User: 0x0000000000000000000000000000000000000009`
  `StartTime: 3461774132`

  `Amount: 9000000000000000000`
  ----------------

  `Lock 9`
  `User: 0x000000000000000000000000000000000000000A`
  `StartTime: 3461774131`

  `Amount: 10000000000000000000`
  ----------------
  Lock 10
  User: 0x000000000000000000000000000000000000000b
  StartTime: 3461774130
  Amount: 11000000000000000000

