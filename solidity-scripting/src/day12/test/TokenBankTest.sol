// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TokenBank} from "../TokenBank.sol";
import "../SosoToken2621.sol";

contract BankTest is Test {
    TokenBank public bank;
    SosoToken2621 public token;

    address public ownerAccount;
    uint256 internal ownerPrivateKey;

    function setUp() public {
        token = new SosoToken2621("SosoToken2612", "STK");
        bank = new TokenBank(address(token));

        ownerPrivateKey = 0xa11ce;
        ownerAccount = vm.addr(ownerPrivateKey);

        token.transfer(ownerAccount, 500 * 10 ** 18);
    }

    function testPermitDeposit() public {
        // Prepare test data
        uint256 depositAmount = 100 * 10 ** 18;
        uint256 deadline = block.timestamp + 10 minutes;
        uint256 nonce = token.nonces(ownerAccount);

        bytes32 permitDataHashStruct = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                ownerAccount,
                address(bank),
                depositAmount,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                permitDataHashStruct
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        // Start to test
        vm.prank(ownerAccount);
        bank.permitDeposit(depositAmount, deadline, v, r, s);

        // Check result
        assertEq(
            token.balanceOf(address(bank)),
            depositAmount,
            "Bank should have recieved 100 tokens"
        );

        assertEq(
            token.balanceOf(ownerAccount),
            400 * 10 ** 18, //500-100
            "OwnerAccount should have 100 tokens in Bank"
        );
    }
}
