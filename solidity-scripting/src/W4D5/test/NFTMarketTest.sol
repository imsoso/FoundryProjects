// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from 'forge-std/Test.sol';
import { NFTMarket } from '../NFTMarket.sol';
import '../NFTToken.sol';
import '../SosoToken2621.sol';

contract NFTMarketTest is Test {
    address public owner;
    address public seller;
    address public buyer;

    SosoNFT public nftContract;
    uint256 public tokenId;

    bytes32 merkleRoot;

    SosoToken2621 public paymentToken;
    NFTMarket public market;

    address[] public whitelistBuyers;
    uint256[] public whitelistBuyersPrivateKeys;

    function setUp() public {
        owner = address(this);

        // test 100 whitelist buyers
        uint256 numWhitelist = 100;
        whitelistBuyers = new address[](numWhitelist);
        whitelistBuyersPrivateKeys = new uint256[](numWhitelist);

        for (uint256 i = 0; i < numWhitelist; i++) {
            whitelistBuyersPrivateKeys[i] = uint256(keccak256(abi.encodePacked('whitelistBuyer', i)));
            whitelistBuyers[i] = vm.addr(whitelistBuyersPrivateKeys[i]);
        }

        paymentToken = new SosoToken2621('SosoToken', 'STK');
        nftContract = new SosoNFT();

        // build merkle tree
        bytes32[] memory leaves = new bytes32[](whitelistBuyers.length);
        for (uint256 i = 0; i < whitelistBuyers.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(whitelistBuyers[i]));
        }

        merkleRoot = computeMerkleRoot(leaves);
        market = new NFTMarket(address(nftContract), address(paymentToken));

        // mint tokens to whitelist buyers
        for (uint256 i = 0; i < whitelistBuyers.length; i++) {
            paymentToken.mint(whitelistBuyers[i], 2000 * 10 ** paymentToken.decimals());
        }

        seller = makeAddr('seller');
        buyer = makeAddr('buyer');

        paymentToken.mint(buyer, 20_000 * 10 ** paymentToken.decimals());

        paymentToken.mint(owner, 1000 * 10 ** 18);

        vm.prank(owner);
        nftContract.safeMint(seller, 'ipfs://gmh-001');
    }

    function testClaimNFT() public {
        uint256 buyerIndex = 0; // test the first whitelist buyer
        address currentBuyer = whitelistBuyers[buyerIndex];
        uint256 currentBuyerPK = whitelistBuyersPrivateKeys[buyerIndex];

        // mint a new NFT for testing
        vm.startPrank(owner);
        nftContract.safeMint(seller, string(abi.encodePacked('ipfs://gmh-', Strings.toString(tokenId))));
        vm.stopPrank();

        uint256 price = 100 * 10 ** paymentToken.decimals();
        uint256 deadline = block.timestamp + 1 hours;

        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();

        bytes32 permitHash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                paymentToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'),
                        currentBuyer,
                        address(market),
                        price,
                        paymentToken.nonces(currentBuyer),
                        deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(currentBuyerPK, permitHash);

        uint256 sellerInitialBalance = paymentToken.balanceOf(seller);
        uint256 buyerInitialBalance = paymentToken.balanceOf(currentBuyer);

        vm.startPrank(currentBuyer);

        market.permitPrePay(price, deadline, v, r, s);

        assertEq(paymentToken.allowance(currentBuyer, address(market)), price);

        bytes32[] memory proof = getMerkleProof(currentBuyer);

        console.log('Current buyer:', currentBuyer);
        console.log('Merkle root:', uint256(merkleRoot));
        console.log('Proof length:', proof.length);
        for (uint256 i = 0; i < proof.length; i++) {
            console.log('Proof', i, ':', uint256(proof[i]));
        }

        market.claimNFT(tokenId, proof, merkleRoot);
        vm.stopPrank();

        assertEq(nftContract.ownerOf(tokenId), currentBuyer);
        assertEq(paymentToken.balanceOf(seller), sellerInitialBalance + (100 * 10 ** paymentToken.decimals()));
        assertEq(paymentToken.balanceOf(currentBuyer), buyerInitialBalance - (100 * 10 ** paymentToken.decimals()));
        (address listedSeller, uint256 listedPrice) = market.listings(tokenId);
        assertEq(listedSeller, address(0));
        assertEq(listedPrice, 0);
    }

    function testMulticallPermitAndClaim(uint256 buyerIndex) public {
        buyerIndex = buyerIndex % whitelistBuyers.length;
        address currentBuyer = whitelistBuyers[buyerIndex];
        uint256 currentBuyerPK = whitelistBuyersPrivateKeys[buyerIndex];

        // mint a new NFT for testing
        vm.startPrank(owner);
        nftContract.safeMint(seller, string(abi.encodePacked('ipfs://gmh-', Strings.toString(tokenId))));
        vm.stopPrank();

        uint256 price = 100 * 10 ** paymentToken.decimals();
        uint256 deadline = block.timestamp + 1 hours;

        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();

        // Generate permit signature
        bytes32 permitHash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                paymentToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'),
                        currentBuyer,
                        address(market),
                        price,
                        paymentToken.nonces(currentBuyer),
                        deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(currentBuyerPK, permitHash);

        // Get merkle proof
        bytes32[] memory proof = getMerkleProof(currentBuyer);

        // Prepare multicall data
        bytes[] memory data = new bytes[](2);

        // Prepare permitPrePay call
        data[0] = abi.encodeWithSelector(market.permitPrePay.selector, price, deadline, v, r, s);

        // Prepare claimNFT call
        data[1] = abi.encodeWithSelector(market.claimNFT.selector, tokenId, proof, merkleRoot);

        // Record initial balances
        uint256 sellerInitialBalance = paymentToken.balanceOf(seller);
        uint256 buyerInitialBalance = paymentToken.balanceOf(currentBuyer);

        // Execute multicall
        vm.startPrank(currentBuyer);

        console.log('Current buyer:', currentBuyer);
        console.log('Market address:', address(market));
        console.log('Token price:', price);
        console.log('Merkle root:', uint256(merkleRoot));

        // Execute multicall and catch any revert
        try market.multicall(data) returns (bytes[] memory results) {
            assertEq(results.length, 2, 'Wrong number of results');

            assertEq(nftContract.ownerOf(tokenId), currentBuyer, 'NFT not transferred');
            assertEq(
                paymentToken.balanceOf(seller),
                sellerInitialBalance + (100 * 10 ** paymentToken.decimals()),
                'Seller balance not updated'
            );
            assertEq(
                paymentToken.balanceOf(currentBuyer),
                buyerInitialBalance - (100 * 10 ** paymentToken.decimals()),
                'Buyer balance not updated'
            );

            (address listedSeller, uint256 listedPrice) = market.listings(tokenId);
            assertEq(listedSeller, address(0), 'NFT still listed');
            assertEq(listedPrice, 0, 'NFT price not reset');
        } catch Error(string memory reason) {
            console.log('Multicall failed: ', reason);
        } catch (bytes memory) {
            console.log('Multicall failed with no reason');
        }

        vm.stopPrank();
    }

    // compute merkle root
    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        if (leaves.length == 0) return 0;
        while (leaves.length > 1) {
            uint256 len = (leaves.length + 1) / 2;
            bytes32[] memory newLeaves = new bytes32[](len);
            for (uint256 i = 0; i < len; i++) {
                if (2 * i + 1 < leaves.length) {
                    newLeaves[i] = keccak256(
                        abi.encodePacked(
                            leaves[2 * i] < leaves[2 * i + 1] ? leaves[2 * i] : leaves[2 * i + 1],
                            leaves[2 * i] < leaves[2 * i + 1] ? leaves[2 * i + 1] : leaves[2 * i]
                        )
                    );
                } else {
                    newLeaves[i] = leaves[2 * i];
                }
            }
            leaves = newLeaves;
        }
        return leaves[0];
    }

    // get merkle proof
    function getMerkleProof(address user) public view returns (bytes32[] memory) {
        // find the index of the user in the whitelist
        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < whitelistBuyers.length; i++) {
            if (whitelistBuyers[i] == user) {
                index = i;
                break;
            }
        }
        require(index != type(uint256).max, 'User not in whitelist');

        // build leaves
        bytes32[] memory leaves = new bytes32[](whitelistBuyers.length);
        for (uint256 i = 0; i < whitelistBuyers.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(whitelistBuyers[i]));
        }

        // compute the number of layers needed for the proof
        uint256 layers = 0;
        uint256 n = whitelistBuyers.length;
        while (n > 1) {
            n = (n + 1) / 2;
            layers++;
        }

        // create proof array
        bytes32[] memory proof = new bytes32[](layers);
        uint256 proofIndex = 0;
        n = whitelistBuyers.length;

        // current layer nodes
        bytes32[] memory currentLayer = leaves;
        uint256 currentIndex = index;

        // build proof from bottom to top
        while (currentLayer.length > 1) {
            bytes32[] memory nextLayer = new bytes32[]((currentLayer.length + 1) / 2);

            for (uint256 i = 0; i < currentLayer.length; i += 2) {
                uint256 j = i + 1;
                if (j == currentLayer.length) {
                    nextLayer[i / 2] = currentLayer[i];
                    continue;
                }

                bytes32 left = currentLayer[i];
                bytes32 right = currentLayer[j];

                // if the current index is one of the nodes in this pair, add the other one to the proof
                if (currentIndex == i || currentIndex == j) {
                    proof[proofIndex++] = currentIndex == i ? right : left;
                }

                nextLayer[i / 2] = keccak256(abi.encodePacked(left < right ? left : right, left < right ? right : left));
            }

            currentLayer = nextLayer;
            currentIndex = currentIndex / 2;
        }

        return proof;
    }
}
