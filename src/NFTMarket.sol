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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarket is IERC721Receiver {
    IERC721 public nftMarket;

    IERC20 public nftToken;

    struct NFTProduct {
        uint256 price;
        address seller;
    }

    mapping(uint256 => NFTProduct) public NFTList;

    constructor(address _nftMarket, address _nftToken) {
        nftMarket = IERC721(_nftMarket);
        nftToken = IERC20(_nftToken);
    }

    // List NFT on the market
    function list(uint256 tokenId, uint256 price) external {
        require(
            nftMarket.ownerOf(tokenId) == msg.sender,
            "You are not the owner"
        );
        require(price > 0, "Price must be greater than zero");
        // Transfer NFT to the market, make it available for sale
        nftMarket.safeTransferFrom(msg.sender, address(this), tokenId);
        NFTList[tokenId] = NFTProduct({price: price, seller: msg.sender});
    }
    function buyNFT(address buyer, uint256 amount, uint256 nftId) public {
        NFTProduct memory aNFT = NFTList[nftId];
        //You cannot buy your own NFT
        require(aNFT.seller != buyer, "You cannot buy your own NFT");

        require(
            nftToken.balanceOf(buyer) >= amount,
            "Insufficient payment token balance"
        );

        require(amount == aNFT.price, "Insufficient token amount to buy NFT");
        require(
            nftToken.transferFrom(buyer, aNFT.seller, aNFT.price),
            "Token transfer failed"
        );

        nftMarket.transferFrom(address(this), buyer, nftId);
        delete NFTList[nftId];
    }

    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata userData
    ) external {
        require(
            msg.sender == address(nftToken),
            "Only the ERC20 token contract can call this"
        );
        uint256 tokenId = abi.decode(userData, (uint256));
        NFTProduct memory aNFT = NFTList[tokenId];
        require(aNFT.price > 0, "NFT is not listed for sale");
        require(amount == aNFT.price, "Incorrect payment amount");

        nftMarket.safeTransferFrom(address(this), from, tokenId);
        nftToken.transfer(aNFT.seller, amount);
        delete NFTList[tokenId];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // do nothing here
        return IERC721Receiver.onERC721Received.selector;
    }
}
