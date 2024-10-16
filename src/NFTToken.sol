// SPDX-License-Identifier: MIT
/*用 ERC721 标准（可复用 OpenZepplin 库）发行一个自己 NFT 合约，并用图片铸造几个 NFT ， 请把图片和 Meta Json数据上传到去中心的存储服务中，请贴出在 OpenSea 的 NFT 链接。

发⾏⼀个 ERC721 Token（⽤⾃⼰的名字）
• 铸造⼏个 NFT，在测试⽹上发⾏，在 Opensea 上查看
• 编写⼀个市场合约 NFTMarket：使⽤⾃⼰发⾏的 ERC20 Token   来买 NFT：
• NFT 持有者可上架 NFT（list() 设置价格 多少个 TOKEN 购买 NFT  ）
• 编写购买NFT ⽅法 buyNFT(uint tokenID, uint amount)，转⼊对应的TOKEN，获取对应的  NFT

 熟悉 ERC721 实现
• https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/
 ERC721/ERC721.sol
 • safeTransferFrom 与合约如何接收 NFT 
• 实现 onERC721Received(
 */
pragma solidity >=0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
contract SosoNFT is ERC721URIStorage  {
        uint256 private _tokenIdCounter;
    constructor() ERC721("SosoNFT", "SSFT") {}
        function mint(address receiver, string memory uri) public returns (uint256) {
            uint256 tokenId = _tokenIdCounter;
            _mint(receiver, tokenId);
            _tokenIdCounter += 1;
            _setTokenURI(tokenId, uri);
            return tokenId;

        }
}
