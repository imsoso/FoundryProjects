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

    function _addLiquidityETH10_RNT1000() private returns (uint amountA, uint amountB, uint liquidity) {
        // Approve tokens
        WETH.deposit{ value: 20 ether }();
        RNT.approve(address(uniswapV2Router), 1000 ether);
        WETH.approve(address(uniswapV2Router), 10 ether);

        tokenWETH = address(WETH);
        tokenRNT = address(RNT);

        // Add liquidity
        (amountA, amountB, liquidity) = uniswapV2Router.addLiquidity(
            tokenWETH,
            tokenRNT,
            10 ether,
            1000 ether,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function testBuyETHWithRNT() public {
        _addLiquidityETH10_RNT1000();

        // Approve and deposit tokens
        uint256 sellAmount = 1 ether;
        RNT.approve(address(myDex), sellAmount);

        address[] memory path = new address[](2);
        path[0] = address(RNT);
        path[1] = address(WETH);

        uint[] memory amountOuts = uniswapV2Router.getAmountsOut(sellAmount, path);

        // amounts[1] is WETH amountOut which should be greater than 0
        assertTrue(amountOuts[amountOuts.length - 1] > 0);

        // get balance before buy eth
        uint256 balanceBeforeBuyETH = address(this).balance;
        console.log('balanceBeforeBuyETH:', balanceBeforeBuyETH);

        // with slippage
        uint256 minBuyAmount = (amountOuts[amountOuts.length - 1] * 99) / 100;

        // Buy ETH
        myDex.buyETH(address(RNT), sellAmount, minBuyAmount);

        // Check if the balance of the contract has increased
        uint256 finalBalance = address(this).balance;
        console.log('finalBalance:', finalBalance);
        assertGe(finalBalance, balanceBeforeBuyETH + minBuyAmount);
    }

    function testSellETHForRNT() public {
        // Add liquidity
        _addLiquidityETH10_RNT1000();

        uint256 balanceRNTBeforeSellETH = RNT.balanceOf(address(this));
        console.log('balanceRNTBeforeSellETH:', balanceRNTBeforeSellETH);

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(RNT);
        
        // amounts[0] => ETH, amounts[1] => RNT
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(1 ether, path);
        assertTrue(amounts[amounts.length - 1] > amounts[0]);
        uint256 minBuyAmount = amounts[amounts.length - 1];

        // sell ETH
        myDex.sellETH{ value: 1 ether }(address(RNT), minBuyAmount);

        // Check if the balance of RNT has increased
        uint256 finalBalance = RNT.balanceOf(address(this));
        assertEq(finalBalance, balanceRNTBeforeSellETH + minBuyAmount);
    }
}
