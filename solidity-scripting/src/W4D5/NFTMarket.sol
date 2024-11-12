// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：

1、基于 Merkel 树验证某用户是否在白名单中
2、在白名单中的用户可以使用上架（和之前的上架逻辑一致）指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。

要求使用 multicall( delegateCall 方式) 一次性调用两个方法：
1、permitPrePay() : 调用token的 permit 进行授权
2、claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 。
*/
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import '@solady/utils/SafeTransferLib.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';

contract NFTMarket is Ownable, Multicall {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // custom errors
    error NotTheOwner();
    error NFTNotApproved();
    error PriceMustBeGreaterThanZero();
    error NotSellerOrNotListed();
    error NFTNotListed();
    error TokenTransferFailed();
    error InvalidToken();
    error InvalidRecipient();
    error InsufficientPayment();
    error NoTokenId();
    error TheSenderIsTheSeller();
    error InvalidSeller();
    error NotSignedByWhitelistSigner();
    error PermitNotSupported();
    error InvalidWhitelistSigner();
    error NotInWhiteList();

    // custom events
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);
    event Refund(address indexed from, uint256 amount);
    event WhitelistBuy(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event PermitPrePay(uint256 amount, uint256 deadline);
    event ClaimNFT(address indexed buyer, uint256 indexed tokenId, uint256 amount);

    // custom structs
    struct Listing {
        address seller;
        uint256 price;
    }

    // this is our payment token
    IERC20 public immutable paymentToken;
    // this is our payment token permit
    IERC20Permit public paymentTokenPermit;
    // indicate if the payment token supports permit(EIP-2612)
    bool public immutable supportsPermit;
    // this is our NFT contract
    IERC721 public immutable nftContract;
    // this is our whitelist signer
    address public whitelistSigner;

    // this is our listing mapping [tokenId => Listing]
    mapping(uint256 => Listing) public listings;

    constructor(address _nftContract, address _paymentToken) Ownable(msg.sender) {
        nftContract = IERC721(_nftContract);
        paymentToken = IERC20(_paymentToken);

        // check if the payment token supports permit
        supportsPermit = _isPermitSupported(_paymentToken);
        if (supportsPermit) {
            paymentTokenPermit = IERC20Permit(_paymentToken);
        }

        // default whitelist signer is the owner
        whitelistSigner = msg.sender;
    }

    // set the whitelist signer
    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        if (_whitelistSigner == address(0)) {
            revert InvalidWhitelistSigner();
        }
        whitelistSigner = _whitelistSigner;
    }

    // this is a helper function to check if the recipient is a contract
    function _isContract(address account) internal view returns (bool) {
        // if the code size is greater than 0, then the account is a contract
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // check if the token supports permit
    function _isPermitSupported(address _token) internal view returns (bool) {
        if (!_isContract(_token)) {
            return false;
        }
        try IERC20Permit(_token).DOMAIN_SEPARATOR() returns (bytes32) {
            return true;
        } catch {
            return false;
        }
    }

    // this is our function to list an NFT
    function list(uint256 tokenId, uint256 price) external {
        // make sure the sender is the owner of the NFT
        if (nftContract.ownerOf(tokenId) != msg.sender) {
            revert NotTheOwner();
        }

        // make sure the NFT is approved for the NFTMarket contract
        bool isIndividuallyApproved = nftContract.getApproved(tokenId) == address(this);
        bool isApprovedForAll = nftContract.isApprovedForAll(msg.sender, address(this));
        if (!isIndividuallyApproved && !isApprovedForAll) {
            revert NFTNotApproved();
        }

        // make sure the price is not zero
        if (price == 0) {
            revert PriceMustBeGreaterThanZero();
        }

        // add the listing to the mapping
        listings[tokenId] = Listing(msg.sender, price);

        // emit the NFTListed event
        emit NFTListed(tokenId, msg.sender, price);
    }

    // this is our function to unlist an NFT
    function unlist(uint256 tokenId) external {
        // make sure the sender is the seller of the NFT
        if (listings[tokenId].seller != msg.sender) {
            revert NotSellerOrNotListed();
        }

        // remove the listing from the mapping
        delete listings[tokenId];

        // emit the NFTUnlisted event
        emit NFTUnlisted(tokenId);
    }

    // this is our function to buy an NFT
    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        // make sure the NFT is listed
        if (listing.price == 0) {
            revert NFTNotListed();
        }
        // make sure the sender is not the seller
        if (msg.sender == listing.seller) {
            revert TheSenderIsTheSeller();
        }

        // transfer the payment token to the seller
        SafeTransferLib.safeTransferFrom(address(paymentToken), msg.sender, listing.seller, listing.price);

        // transfer NFT from seller to buyer
        _safeTransferFromSellerToBuyer(tokenId, msg.sender);

        // emit the NFTSold event
        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    // this is our private function to transfer NFT from seller to buyer
    function _safeTransferFromSellerToBuyer(uint256 tokenId, address buyer) private {
        Listing memory listing = listings[tokenId];
        // transfer NFT from seller to buyer
        nftContract.safeTransferFrom(listing.seller, buyer, tokenId);
        // delete the listing
        delete listings[tokenId];
    }

    // need to be whitelisted to buy
    function permitBuy(
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory whitelistSignature
    ) external {
        // make sure the payment token supports permit
        if (!supportsPermit) {
            revert PermitNotSupported();
        }

        Listing memory listing = listings[tokenId];
        // make sure the NFT is listed
        if (listing.price == 0) {
            revert NFTNotListed();
        }
        // make sure the buyer is not the seller
        if (msg.sender == listing.seller) {
            revert TheSenderIsTheSeller();
        }

        // verify the whitelist signature
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, tokenId));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(whitelistSignature);

        // not signed by the whitelist signer
        if (signer != whitelistSigner) {
            revert NotSignedByWhitelistSigner();
        }

        // use the permit function of ERC2612
        paymentTokenPermit.permit(msg.sender, address(this), price, deadline, v, r, s);

        // transfer the payment token to the seller
        SafeTransferLib.safeTransferFrom(address(paymentToken), msg.sender, listing.seller, price);

        // transfer NFT from seller to buyer
        _safeTransferFromSellerToBuyer(tokenId, msg.sender);

        // emit the WhitelistBuy event
        emit WhitelistBuy(tokenId, msg.sender, price);
    }

    // Use token permit to authorize
    function permitPrePay(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        // make sure the payment token supports permit
        if (!supportsPermit) {
            revert PermitNotSupported();
        }

        paymentTokenPermit.permit(msg.sender, address(this), amount, deadline, v, r, s);

        emit PermitPrePay(amount, deadline);
    }

    // use merkle tree to verify whitelist and permit to prepay and buy nft
    function claimNFT(uint256 tokenId, bytes32[] calldata proof, bytes32 merkleRoot) external {
        // verify if the user is in the whitelist
        if (!verifyWhitelistWithMerkleTree(msg.sender, proof, merkleRoot)) {
            revert NotInWhiteList();
        }
        // use permit to prepay 100 token
        uint256 amount = 100;
        Listing memory listing = listings[tokenId];
        // transfer 100 tokens to the seller
        SafeTransferLib.safeTransferFrom(address(paymentToken), msg.sender, listing.seller, amount);

        // transfer out the NFT
        _safeTransferFromSellerToBuyer(tokenId, msg.sender);

        emit ClaimNFT(msg.sender, tokenId, amount);
    }

    // verify the whitelist using Merkle Tree
    function verifyWhitelistWithMerkleTree(address user, bytes32[] calldata proof, bytes32 merkleRoot) internal pure returns (bool) {
        // calculate the leaf node hash
        bytes32 leaf = keccak256(abi.encodePacked(user));

        // verify if the user is in the whitelist
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}
