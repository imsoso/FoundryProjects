// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract NFTMarket is IERC721Receiver {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IERC721 public nftMarket;
    IERC20 public nftToken;

    struct NFTProduct {
        uint256 price;
        address seller;
    }

    mapping(uint256 => NFTProduct) public NFTList;

    address public whitelistSigner;
    IERC20Permit public immutable tokenPermit;

    constructor(address _nftMarket, address _nftToken) {
        nftMarket = IERC721(_nftMarket);
        nftToken = IERC20(_nftToken);

        whitelistSigner = msg.sender;
        tokenPermit = IERC20Permit(_nftToken);
    }

    // custom events
    event NFTListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event NFTSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );
    event NFTUnlisted(uint256 indexed tokenId);
    event Refund(address indexed from, uint256 amount);
    event WhitelistBuy(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );

    error NFTNotForSale();
    error NotTheSeller();
    error NotSignedByWhitelist();
    error InvalidWhitelistSigner();

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

        // emit the NFTListed event
        emit NFTListed(tokenId, msg.sender, price);
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

        emit NFTSold(nftId, aNFT.seller, msg.sender, aNFT.price);
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
        emit NFTSold(tokenId, aNFT.seller, msg.sender, aNFT.price);
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

    /*
修改Token 购买 NFT NTFMarket 合约，添加功能 permitBuy() 实现只有离线授权的白名单地址才可以购买 NFT （用自己的名称发行 NFT，再上架） 。白名单具体实现逻辑为：项目方给白名单地址签名，白名单用户拿到签名信息后，传给 permitBuy() 函数，在permitBuy()中判断时候是经过许可的白名单用户，如果是，才可以进行后续购买，否则 revert 。
*/
    function permitBuy(
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory whitelistSignature
    ) external {
        // Defendence check
        NFTProduct memory aNFT = NFTList[tokenId];
        if (aNFT.price == 0) {
            revert NFTNotForSale();
        }
        if (msg.sender == aNFT.seller) {
            revert NotTheSeller();
        }

        // Verify signature in whitelist
        bytes32 messageWithSenderAndToken = keccak256(
            abi.encodePacked(msg.sender, tokenId)
        );
        bytes32 ethSignedWithSenderAndToken = messageWithSenderAndToken
            .toEthSignedMessageHash();
        address theSigner = ethSignedWithSenderAndToken.recover(
            whitelistSignature
        );

        if (theSigner != whitelistSigner) {
            revert NotSignedByWhitelist();
        }

        tokenPermit.permit(msg.sender, address(this), price, deadline, v, r, s);

        buyNFT(msg.sender, price, tokenId);

        emit WhitelistBuy(tokenId, msg.sender, price);
    }

    function setWhitelistSigner(address _whitelistSigner) external {
        if (_whitelistSigner == address(0)) {
            revert InvalidWhitelistSigner();
        }
        whitelistSigner = _whitelistSigner;
    }
}
