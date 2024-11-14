// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'forge-std/Test.sol';
import { MyDex } from '../src/MyDex/MyDex.sol';
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

import '../src/MyDex/WETH9.sol';
import '../src/UniswapV2/UniswapV2Factory.sol';
import '../src/UniswapV2/UniswapV2Router02.sol';
import '../src/UniswapV2/UniswapV2Pair.sol';
import '../src/UniswapV2/interfaces/IUniswapV2Router02.sol';
import '../src/UniswapV2/interfaces/IERC20.sol';
import '../src/UniswapV2/libraries/UniswapV2Library.sol';

contract RNTToken is ERC20, Ownable {
    constructor() ERC20('RNTToken', 'RNT') Ownable(msg.sender) {
        _mint(msg.sender, 10000 ether);
    }

    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }
}

contract MyDexTest is Test {
    MyDex myDex;
    WETH9 WETH;
    IUniswapV2Router02 uniswapV2Router;
    UniswapV2Factory factory;
    IERC20 RNT;
    address tokenWETH;
    address tokenRNT;
    function setUp() public {
        // Fork the mainnet at a specific block
        // vm.createSelectFork("mainnet", 12345678); // Replace with a recent block number
        WETH = new WETH9();
        factory = new UniswapV2Factory(address(0));
        uniswapV2Router = new UniswapV2Router02(address(factory), address(WETH));
        RNT = IERC20(address(new RNTToken()));
        myDex = new MyDex(address(uniswapV2Router));
    }
