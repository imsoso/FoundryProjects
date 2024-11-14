// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '../UniswapV2/interfaces/IUniswapV2Router02.sol';
import '../UniswapV2/interfaces/IERC20.sol';
import './IWETH.sol';

/*
➤ 部署自己的 UniswapV2 Dex
➤ 编写 MyDex 合约，任何人都可通过 MyDex 来买卖ETH  
➤ 任何人都可以通过 sellETH 方法出售ETH兑换成 USDT，也可以通过 buyETH 将 USDT 兑换成 ETH。
➤ Test合约测试：创建RNT-ETH交易对、添加初始化流动性、移除流动性、使用 RNT兑换 ETH，用 ETH兑换RNT
*/

contract MyDex {
    IUniswapV2Router02 public uniswapV2Router;
    IWETH public WETH;

    event TokenSwapped(uint amountOut);
    constructor(address _uniswapV2Router) {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        WETH = IWETH(uniswapV2Router.WETH());
    }

    function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint amountOut) {
        uint[] memory amounts = uniswapV2Router.getAmountsOut(amountIn, path);
        amountOut = amounts[amounts.length - 1];
    }

    /**
     * @dev 卖出ETH，兑换成 buyToken
     *      msg.value 为出售的ETH数量
     * @param buyToken 兑换的目标代币地址
     * @param minBuyAmount 要求最低兑换到的 buyToken 数量
     */
    function sellETH(address buyToken, uint256 minBuyAmount) external payable {
        require(msg.value > 0, 'Invalid ETH amount');

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = buyToken;

        uint amountOut = getAmountsOut(msg.value, path);
        require(amountOut >= minBuyAmount, 'Required token amount not met');

        uniswapV2Router.swapETHForExactTokens{ value: msg.value }(amountOut, path, msg.sender, block.timestamp);

        emit TokenSwapped(amountOut);
    }

    /**
     * @dev 买入ETH，用 sellToken 兑换
     * @param sellToken 出售的代币地址
     * @param sellAmount 出售的代币数量
     * @param minBuyAmount 要求最低兑换到的ETH数量
     */
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external {}
}
