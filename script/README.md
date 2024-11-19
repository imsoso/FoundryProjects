## Usage
使⽤你熟悉的语⾔，利⽤ flashbot API eth_sendBundle 捆绑 OpenspaceNFT 的开启预售和 presale 交易
预售的交易(sepolia 测试⽹络)，并使⽤ flashbots_getBundleStats 查询状态，最终打印交易哈希和 stats 信息

### Reference
* https://learnblockchain.cn/article/8938
* https://www.wtf.academy/docs/ethers-102/Flashbots/
### Run

```shell
$ node script/flashbots.js
```

### Result

```
Connected to provider: https://sepolia.infura.io/v3/37c4affd9b39416c84029afdfaaab901
Current block number: 7106165
Wallet address: 0x2e04aF48d11F4E505F09e253B119BfDa6772df54
Bundle transactions: [
  {
    "signer": {
      "provider": {},
      "address": "0x2e04aF48d11F4E505F09e253B119BfDa6772df54"
    },
    "transaction": {
      "to": "0x07dd1daba01489c67321766125b42e72d8eaa622",
      "data": "0x04c98b2b",
      "chainId": 11155111,
      "gasLimit": 100000,
      "maxFeePerGas": "10000000000",
      "maxPriorityFeePerGas": "2000000000",
      "type": 2
    }
  },
  {
    "signer": {
      "provider": {},
      "address": "0x2e04aF48d11F4E505F09e253B119BfDa6772df54"
    },
    "transaction": {
      "to": "0x07dd1daba01489c67321766125b42e72d8eaa622",
      "data": "0xcaa07a0c",
      "chainId": 11155111,
      "gasLimit": 100000,
      "maxFeePerGas": "10000000000",
      "maxPriorityFeePerGas": "2000000000",
      "type": 2
    }
  }
]
Simulation results: {
  "bundleGasPrice": "2000000000",
  "bundleHash": "0x4eadbcc3ff4d1369cb04d8d4eecd2922136712d9b2482b646dda10ea05b508d9",
  "coinbaseDiff": "85150000000000",
  "ethSentToCoinbase": "0",
  "gasFees": "85150000000000",
  "results": [
    {
      "txHash": "0xca2adcc13dd66e87b5b5d1c318240d26418b357f2ca4b4d47969f7aab248b2a4",
      "gasUsed": 21278,
      "gasPrice": "2000000000",
      "gasFees": "42556000000000",
      "fromAddress": "0x2e04aF48d11F4E505F09e253B119BfDa6772df54",
      "toAddress": "0x07Dd1dabA01489c67321766125b42E72D8EAA622",
      "coinbaseDiff": "42556000000000",
      "ethSentToCoinbase": "0",
      "error": "execution reverted",
      "value": null
    },
    {
      "txHash": "0x25745840adee769e6d6c61558cb23c9387fce64d9d96557a9e87a047b3c4c50e",
      "gasUsed": 21297,
      "gasPrice": "2000000000",
      "gasFees": "42594000000000",
      "fromAddress": "0x2e04aF48d11F4E505F09e253B119BfDa6772df54",
      "toAddress": "0x07Dd1dabA01489c67321766125b42E72D8EAA622",
      "coinbaseDiff": "42594000000000",
      "ethSentToCoinbase": "0",
      "error": "execution reverted",
      "value": null
    }
  ],
  "stateBlockNumber": 7106165,
  "totalGasUsed": 42575,
  "firstRevert": {
    "txHash": "0xca2adcc13dd66e87b5b5d1c318240d26418b357f2ca4b4d47969f7aab248b2a4",
    "gasUsed": 21278,
    "gasPrice": "2000000000",
    "gasFees": "42556000000000",
    "fromAddress": "0x2e04aF48d11F4E505F09e253B119BfDa6772df54",
    "toAddress": "0x07Dd1dabA01489c67321766125b42E72D8EAA622",
    "coinbaseDiff": "42556000000000",
    "ethSentToCoinbase": "0",
    "error": "execution reverted",
    "value": null
  }
}
Bundle response: {
  "bundleTransactions": [
    {
      "signedTransaction": "0x02f87383aa36a73084773594008502540be400830186a09407dd1daba01489c67321766125b42e72d8eaa622808404c98b2bc080a0799c32ec1b335492d9832876c389c79c43fc236a515c124c55f0dbfb8c2abe46a079ba818a93debcf6543a6f6f531b5115b498414a3fe4124cebb3f47e307ae6d7",
      "hash": "0xca2adcc13dd66e87b5b5d1c318240d26418b357f2ca4b4d47969f7aab248b2a4",
      "account": "0x2e04aF48d11F4E505F09e253B119BfDa6772df54",
      "nonce": 48
    },
    {
      "signedTransaction": "0x02f87383aa36a73184773594008502540be400830186a09407dd1daba01489c67321766125b42e72d8eaa6228084caa07a0cc001a0657c175faffe1d12d1062efacfa826655b2a6fdb9ac47728adbac9ed88e5dc7ea024b286389b3c243f23a709abb4e2e8cd850d2d1d7151af6056990d1ad292f7a8",
      "hash": "0x25745840adee769e6d6c61558cb23c9387fce64d9d96557a9e87a047b3c4c50e",
      "account": "0x2e04aF48d11F4E505F09e253B119BfDa6772df54",
      "nonce": 49
    }
  ],
  "bundleHash": "0x4eadbcc3ff4d1369cb04d8d4eecd2922136712d9b2482b646dda10ea05b508d9"
}
Bundle included in block
Bundle stats: {
  "isHighPriority": true,
  "isSentToMiners": false,
  "isSimulated": true,
  "simulatedAt": "2024-11-19T02:13:11.688Z",
  "submittedAt": "2024-11-19T02:13:11.672Z"
}
```