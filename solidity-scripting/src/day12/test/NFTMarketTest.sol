// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../NFTMarket.sol";
import "../NFTToken.sol";
import "../SosoToken2621.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    SosoToken2621 public tokenPermit;
    address public owner;
    address public seller;
    address public whitelistBuyer;
    address public whitelistSigner;

    uint256 public whitelistBuyerPrivateKey;
    uint256 public whitelistSignerPrivateKey;

    NFTMarket public nftMarket;
    SosoNFT public nftContract;

    function setUp() public {
        owner = address(this);
        seller = makeAddr("seller");

        tokenPermit = new SosoToken2621("SosoToken2621", "STK");
        nftContract = new SosoNFT();
        nftMarket = new NFTMarket(address(nftContract), address(tokenPermit));

        whitelistSignerPrivateKey = 0x3389;
        whitelistSigner = vm.addr(whitelistSignerPrivateKey);
        whitelistBuyerPrivateKey = 0x4489;
        whitelistBuyer = vm.addr(whitelistBuyerPrivateKey);

        tokenPermit.mint(whitelistBuyer, 2000 * 10 ** tokenPermit.decimals());

        vm.prank(owner);
        nftContract.safeMint(
            seller,
            "https://chocolate-acceptable-hawk-967.mypinata.cloud/ipfs/QmSpTwSkZy8Hx7xBDrugDmbzRf5kkwnsVxdsbcAnaHAawu/0"
        );
    }

    function testPermitBuySuccess() public {
        // Prepare variables
        uint256 price = 10 * 10 ** tokenPermit.decimals();
        uint256 tokenId = 0;
        uint256 deadline = block.timestamp + 10 minutes;

        vm.prank(owner);
        nftMarket.setWhitelistSigner(whitelistSigner);

        // Stock NFT
        vm.startPrank(seller);
        nftContract.approve(address(nftMarket), tokenId);
        nftMarket.list(tokenId, price);
        vm.stopPrank();

        // Signature
        bytes32 messageWithSenderAndToken = keccak256(
            abi.encodePacked(whitelistBuyer, tokenId)
        );
        bytes32 ethSignedWithSenderAndToken = messageWithSenderAndToken
            .toEthSignedMessageHash();
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
            whitelistSignerPrivateKey,
            ethSignedWithSenderAndToken
        );
        bytes memory whitelistSignature = abi.encodePacked(r1, s1, v1);
        bytes32 permitHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                tokenPermit.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                        ),
                        whitelistBuyer,
                        address(nftMarket),
                        price,
                        tokenPermit.nonces(whitelistBuyer),
                        deadline
                    )
                )
            )
        );

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
            whitelistBuyerPrivateKey,
            permitHash
        );

        // execute permitBuy
        vm.prank(whitelistBuyer);
        nftMarket.permitBuy(
            tokenId,
            price,
            deadline,
            v2,
            r2,
            s2,
            whitelistSignature
        );

        // Check results
        assertEq(nftContract.ownerOf(tokenId), whitelistBuyer);
        assertEq(tokenPermit.balanceOf(seller), price);
        (uint256 listedPrice, address listedSeller) = nftMarket.NFTList(
            tokenId
        );
        assertEq(listedSeller, address(0));
        assertEq(listedPrice, 0);
    }

    // function testPermitBuyNotWhitelisted() public {
    //     uint256 price = 100 * 10 ** tokenPermit.decimals();
    //     uint256 tokenId = 0;
    //     uint256 deadline = block.timestamp + 1 hours;

    //     // set whitelist signer
    //     vm.prank(owner);
    //     nftMarket.setWhitelistSigner(whitelistSigner);

    //     // list NFT
    //     vm.startPrank(seller);
    //     nftContract.approve(address(nftMarket), tokenId);
    //     nftMarket.list(tokenId, price);
    //     vm.stopPrank();

    //     // generate invalid whitelist signature
    //     bytes32 whitelistMessageHash = keccak256(
    //         abi.encodePacked(whitelistBuyer, tokenId)
    //     );
    //     (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(
    //         uint256(keccak256(abi.encodePacked("invalidSigner"))),
    //         whitelistMessageHash
    //     );
    //     bytes memory whitelistSignature = abi.encodePacked(r1, s1, v1);

    //     // generate ERC2612 permit signature
    //     bytes32 permitHash = keccak256(
    //         abi.encodePacked(
    //             "\x19\x01",
    //             tokenPermit.DOMAIN_SEPARATOR(),
    //             keccak256(
    //                 abi.encode(
    //                     keccak256(
    //                         "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    //                     ),
    //                     whitelistBuyer,
    //                     address(nftMarket),
    //                     price,
    //                     tokenPermit.nonces(whitelistBuyer),
    //                     deadline
    //                 )
    //             )
    //         )
    //     );

    //     // sign the permit hash
    //     (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(
    //         whitelistBuyerPrivateKey,
    //         permitHash
    //     );

    //     // try to execute permitBuy, should fail
    //     vm.prank(whitelistBuyer);
    //     vm.expectRevert(NFTMarket.NotSignedByWhitelistSigner.selector);
    //     nftMarket.permitBuy(
    //         tokenId,
    //         price,
    //         deadline,
    //         v2,
    //         r2,
    //         s2,
    //         whitelistSignature
    //     );
    // }
}
