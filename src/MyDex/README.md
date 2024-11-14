## Usage

### Test

```shell
$ forge test  --match-contract MyDexTest -vvvv --fork-url sepolia --fork-block-number 7075401
```

### Test Result

```
Ran 2 tests for test/MyDexTest.sol:MyDexTest
[PASS] testBuyETHWithRNT() (gas: 2443206)
[PASS] testSellETHForRNT() (gas: 2461198)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 2.32ms (2.22ms CPU time)
```