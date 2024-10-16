// SPDX-License-Identifier: MIT
/*
编写一个简单的 NFTMarket 合约，使用自己发行的ERC20 扩展 Token 来买卖 NFT， NFTMarket 的函数有：
list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买。
buyNFT(uint tokenID, uint amount) : 普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。
实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能。
 */
pragma solidity >=0.8.20;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract NFTMarket is IERC721Receiver {
    // NFT contract
    IERC721 public nftMarket;
    constructor(IERC721 _nftContract) {
        nftMarket = _nftContract;
    }

    // List NFT on the market
    function list(uint256 tokenId, uint256 price) external {
        // Transfer NFT to the market, make it available for sale
        nftMarket.safeTransferFrom(msg.sender, address(this), tokenId);
    }
}