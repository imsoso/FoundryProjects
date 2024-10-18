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
import {BaseERC20} from "../src/MyERCToken.sol";
import {SosoNFT} from "../src/NFTToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketTest is Test {
    NFTMarket aNftMarket;
    BaseERC20 aToken;
    SosoNFT aNFT;

    uint256 nftId;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        aToken = new BaseERC20();
        aNFT = new SosoNFT();
        nftId = aNFT.mint(
            alice,
            "https://chocolate-acceptable-hawk-967.mypinata.cloud/ipfs/QmSpTwSkZy8Hx7xBDrugDmbzRf5kkwnsVxdsbcAnaHAawu/0"
        );

        aNftMarket = new NFTMarket(address(aNFT), address(aToken));
    }

    function test_list_not_owner() public {
        vm.expectRevert("You are not the owner");
        aNftMarket.list(nftId, 100);
    }

    function test_list_zero_price() public {
        vm.startPrank(alice);
        aNFT.approve(address(aNftMarket), nftId);
        vm.expectRevert("Price must be greater than zero");
        aNftMarket.list(nftId, 0);
        vm.stopPrank();
    }

    function test_list_succeed() public {
        vm.startPrank(alice);
        aNFT.approve(address(aNftMarket), nftId);
        aNftMarket.list(nftId, 100);
        vm.stopPrank();
    }

    function test_buy_insuficient_balance() public {
        vm.expectRevert("Insufficient payment token balance");
        aNftMarket.buyNFT(alice, 100, nftId);
    }

    function test_buy_own() public {
        vm.startPrank(alice);
        aNFT.approve(address(aNftMarket), nftId);
        aNftMarket.list(nftId, 100);
        vm.expectRevert("You cannot buy your own NFT");
        aNftMarket.buyNFT(alice, 100, nftId);
        vm.stopPrank();
    }

    function test_buy_succeed() public {
        vm.startPrank(alice);
        aNFT.approve(address(aNftMarket), nftId);

        aNftMarket.list(nftId, 100);
        vm.stopPrank();

        deal(address(aToken), bob, 10000);
        vm.prank(bob);
        aToken.approve(address(aNftMarket), 200);

        aNftMarket.buyNFT(bob, 100, nftId);
        assertEq(aNFT.ownerOf(nftId), bob, "NFT is not belong to you");
    }

    function test_buy_twice() public {
        vm.startPrank(alice);
        aNFT.approve(address(aNftMarket), nftId);

        aNftMarket.list(nftId, 100);
        vm.stopPrank();

        deal(address(aToken), bob, 10000);
        vm.prank(bob);
        aToken.approve(address(aNftMarket), 300);

        aNftMarket.buyNFT(bob, 100, nftId);
        vm.expectRevert("Insufficient token amount to buy NFT");
        aNftMarket.buyNFT(bob, 100, nftId);
    }
    function test_too_much_token() public {
        vm.startPrank(alice);
        aNFT.approve(address(aNftMarket), nftId);

        aNftMarket.list(nftId, 100);
        vm.stopPrank();

        deal(address(aToken), bob, 10000);
        vm.prank(bob);
        aToken.approve(address(aNftMarket), 300);

        vm.expectRevert("Insufficient token amount to buy NFT");
        aNftMarket.buyNFT(bob, 200, nftId);
    }

    /// forge-config: default.fuzz.runs = 100
    function test_fuzz_buy(uint256 price, address buyer) public {
        vm.startPrank(alice);
        price = bound(price, 0.01 ether, 10000 ether);
        vm.assume(price > 0.01 ether && price < 10000 ether);

        aNFT.approve(address(aNftMarket), nftId);
        // Test with random price
        aNftMarket.list(nftId, price);
        vm.stopPrank();

        vm.prank(buyer);
        aToken.approve(address(aNftMarket), price);
        deal(address(aToken), buyer, price);

        // Test with random address
        aNftMarket.buyNFT(buyer, price, nftId);
    }
}
