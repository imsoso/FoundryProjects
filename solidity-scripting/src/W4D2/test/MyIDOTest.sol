// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyIDO} from "../MyIDO.sol";
import {MyToken} from "../../MyToken.sol";


contract MyIDOTest is Test {
    MyIDO public myIDO;
    MyToken public token;

    address public ownerAccount;
    address public contributorAlice;
    address public contributorBob;


    function setUp() public {
        token = new MyToken("MyToken", "TKN");
        myIDO = new MyIDO(token, 0.0001 ether, 100 ether, 200 ether, 1 weeks, 1000000);
        // transfer all mint token to IDO contract  
        token.transfer(address(myIDO), token.balanceOf(address(this)));

        contributorAlice = makeAddr("Alice");
        contributorBob = makeAddr("Bob");
    }


    function testContributeSucceed() public {
        vm.deal(contributorAlice, 100 ether);
        vm.prank(contributorAlice);
        myIDO.contribute{value: 0.01 ether}();
        uint256 IDOBalance = myIDO.currentTotalFunding();
        uint256 aliceContribution = myIDO.balances(contributorAlice);

        assertEq(IDOBalance, aliceContribution, "Incorrect funding amount");
    }

    function testClaimTokens() public {
        vm.deal(contributorAlice, 1000 ether);
        vm.startPrank(contributorAlice);
        myIDO.contribute{value: 100 ether}();

        myIDO.claimTokens();
        uint256 aliceTokenBalance = token.balanceOf(contributorAlice);
        assertEq(aliceTokenBalance, 1000000, "Alice token balance should be greater than 0");
        vm.stopPrank();
    }



}
