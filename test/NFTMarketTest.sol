// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;
/*
上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
*/
import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;

    function setUp() public {}
}
