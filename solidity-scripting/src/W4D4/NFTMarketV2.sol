// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
/*
➤ 签名 NFT 上架信息
➤ 使⽤离线签名和验证存储NFT上架， 展⽰最新的 NFT 上架清单
➤ 完善 NFTMarket合约，使⽤ETH买⼊NFT
➤ Option：在TheGraph中记录NFT记录，并在⽹页中展⽰NFT交易动态
*/

contract NFTMarketV2 is
    Ownable(msg.sender),
    EIP712("OpenSpaceNFTMarket", "1"),
    Initializable
{
    address public constant ETH_FLAG =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 public constant feeBP = 30; // 30/10000 = 0.3%
    address public whiteListSigner;
    address public feeTo;
    mapping(bytes32 => SellOrder) public listingOrders; // orderId -> order book
    mapping(address => mapping(uint256 => bytes32)) private _lastIds; //  nft -> lastOrderId

    struct SellOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    // State variables
    address public implAddress; // Implementation address for clone

    function initialize(address owner_) public initializer {
        _transferOwnership(owner_);
    }

    //only owner can set implAddress
    function setImplAddress(address _implAddress) public onlyOwner {
        implAddress = _implAddress;
    }

    function listing(
        address nft,
        uint256 tokenId
    ) external view returns (bytes32) {
        bytes32 id = _lastIds[nft][tokenId];
        return listingOrders[id].seller == address(0) ? bytes32(0x00) : id;
    }

    function list(
        address nft,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external {
        require(deadline > block.timestamp, "MKT: deadline is in the past");
        require(price > 0, "MKT: price is zero");
        require(
            payToken == ETH_FLAG || IERC20(payToken).totalSupply() > 0,
            "MKT: payToken is not valid"
        );

        // safe check
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "MKT: not owner");
        require(
            IERC721(nft).getApproved(tokenId) == address(this) ||
                IERC721(nft).isApprovedForAll(msg.sender, address(this)),
            "MKT: not approved"
        );

        SellOrder memory order = SellOrder({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            deadline: deadline
        });

        bytes32 orderId = keccak256(abi.encode(order));
        // safe check repeat list
        require(
            listingOrders[orderId].seller == address(0),
            "MKT: order already listed"
        );
        listingOrders[orderId] = order;
        _lastIds[nft][tokenId] = orderId; // reset
        emit List(nft, tokenId, orderId, msg.sender, payToken, price, deadline);
    }

    function cancel(bytes32 orderId) external {
        address seller = listingOrders[orderId].seller;
        // safe check repeat list
        require(seller != address(0), "MKT: order not listed");
        require(seller == msg.sender, "MKT: only seller can cancel");
        delete listingOrders[orderId];
        emit Cancel(orderId);
    }

    function buy(bytes32 orderId) public payable {
        _buy(orderId, feeTo);
    }

    function buy(
        bytes32 orderId,
        bytes calldata signatureForWL
    ) external payable {
        _checkWL(signatureForWL);
        // trade fee is zero
        _buy(orderId, address(0));
    }

    function _buy(bytes32 orderId, address feeReceiver) private {
        // 0. load order info to memory for check and read
        SellOrder memory order = listingOrders[orderId];

        // 1. check
        require(order.seller != address(0), "MKT: order not listed");
        require(order.deadline > block.timestamp, "MKT: order expired");

        // 2. remove order info before transfer
        delete listingOrders[orderId];
        // 3. trasnfer NFT
        IERC721(order.nft).safeTransferFrom(
            order.seller,
            msg.sender,
            order.tokenId
        );

        // 4. trasnfer token
        // fee 0.3% or 0
        uint256 fee = feeReceiver == address(0)
            ? 0
            : (order.price * feeBP) / 10000;
        // safe check
        if (order.payToken == ETH_FLAG) {
            require(msg.value == order.price, "MKT: wrong eth value");
        } else {
            require(msg.value == 0, "MKT: wrong eth value");
        }
        _transferOut(order.payToken, order.seller, order.price - fee);
        if (fee > 0) _transferOut(order.payToken, feeReceiver, fee);

        emit Sold(orderId, msg.sender, fee);
    }

    function _transferOut(address token, address to, uint256 amount) private {
        if (token == ETH_FLAG) {
            // eth
            (bool success, ) = to.call{value: amount}("");
            require(success, "MKT: transfer failed");
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, to, amount);
        }
    }

    bytes32 constant WL_TYPEHASH = keccak256("IsWhiteList(address user)");

    function _checkWL(bytes calldata signature) private view {
        // check whiteListSigner for buyer
        bytes32 wlHash = _hashTypedDataV4(
            keccak256(abi.encode(WL_TYPEHASH, msg.sender))
        );
        address signer = ECDSA.recover(wlHash, signature);
        require(signer == whiteListSigner, "MKT: not whiteListSigner");
    }

    // admin functions
    function setWhiteListSigner(address signer) external onlyOwner {
        require(signer != address(0), "MKT: zero address");
        require(whiteListSigner != signer, "MKT:repeat set");
        whiteListSigner = signer;

        emit SetWhiteListSigner(signer);
    }

    function setFeeTo(address to) external onlyOwner {
        require(feeTo != to, "MKT:repeat set");
        feeTo = to;

        emit SetFeeTo(to);
    }

    function listWithSignature(
        address nft,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(deadline > block.timestamp, "MKT: deadline is in the past");
        require(price > 0, "MKT: price is zero");
        require(
            payToken == ETH_FLAG || IERC20(payToken).totalSupply() > 0,
            "MKT: payToken is not valid"
        );
        // safe check
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "MKT: not owner");
        require(
            IERC721(nft).getApproved(tokenId) == address(this) ||
                IERC721(nft).isApprovedForAll(msg.sender, address(this)),
            "MKT: not approved"
        );

        SellOrder memory order = SellOrder({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            deadline: deadline
        });

        bytes32 orderId = keccak256(abi.encode(order));
        // safe check repeat list
        require(
            listingOrders[orderId].seller == address(0),
            "MKT: order already listed"
        );
        address signer;
        if (order.payToken == ETH_FLAG) {
            signer = ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(orderId),
                signature
            );
        } else {
            signer = ECDSA.recover(
                MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), orderId),
                signature
            );
        }
        require(signer == msg.sender, "Invalid signature");

        listingOrders[orderId] = order;
        _lastIds[nft][tokenId] = orderId; // reset

        emit List(nft, tokenId, orderId, msg.sender, payToken, price, deadline);
    }

    function permitBuy(
        bytes32 orderId,
        uint256 amount,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, orderId, amount, deadline, nonce)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer == msg.sender, "Invalid signature");
        SellOrder memory order = listingOrders[orderId];

        IERC20(order.payToken).transferFrom(msg.sender, address(this), amount);
        IERC721(order.nft).safeTransferFrom(
            address(this),
            msg.sender,
            order.tokenId
        );

        emit PermitSold(orderId, msg.sender, signer);
    }

    event List(
        address indexed nft,
        uint256 indexed tokenId,
        bytes32 orderId,
        address seller,
        address payToken,
        uint256 price,
        uint256 deadline
    );
    event Cancel(bytes32 orderId);
    event Sold(bytes32 orderId, address buyer, uint256 fee);
    event PermitSold(bytes32 orderId, address buyer, address signer);
    event SetFeeTo(address to);
    event SetWhiteListSigner(address signer);
}
