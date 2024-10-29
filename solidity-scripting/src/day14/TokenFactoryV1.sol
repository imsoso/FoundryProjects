pragma solidity ^0.8.20;
/*
实现⼀个可升级的工厂合约，工厂合约有两个方法： deployInscription(string symbol, uint totalSupply, uint perMint) ，该方法用来创建 ERC20 token，（模拟铭文的 deploy）， symbol 表示 Token 的名称，totalSupply 表示可发行的数量，perMint 用来控制每次发行的数量，用于控制mintInscription函数每次发行的数量 mintInscription(address tokenAddr) 用来发行 ERC20 token，每次调用一次，发行perMint指定的数量。
 
要求： 
• 合约的第⼀版本用普通的 new 的方式发行 ERC20 token 。 
• 第⼆版本，deployInscription 加入一个价格参数 price deployInscription(string symbol, uint totalSupply, uint perMint, uint price) , price 表示发行每个 token 需要支付的费用，并且 第⼆版本使用最小代理的方式以更节约 gas 的方式来创建 ERC20 token，需要同时修改 mintInscription 的实现以便收取每次发行的费用。
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract FactoryERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
contract TokenFactoryV1 {
    struct TokenInfo {
        address tokenAddress;
        uint256 perMint;
    }
    mapping(string => TokenInfo) public tokens;

    function deployInscription(
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint
    ) external {
        require(
            tokens[symbol].tokenAddress == address(0),
            "Token already exists"
        );

        FactoryERC20 newToken = new FactoryERC20("Inscription Token", symbol);
        newToken.mint(address(this), totalSupply);

        tokens[symbol] = TokenInfo(address(newToken), perMint);
    }

    function mintInscription(string memory symbol) external {
        TokenInfo storage tokenInfo = tokens[symbol];
        require(tokenInfo.tokenAddress != address(0), "Token does not exist");

        FactoryERC20(tokenInfo.tokenAddress).mint(
            msg.sender,
            tokenInfo.perMint
        );
    }
}
