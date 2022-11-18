pragma solidity 0.8.7;

import "./PoolFactory.sol";
import "./INSPool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";



interface IFactory {

    function getPool(address token1, address token2) external view returns(address pool); 
}



contract NSRouter {
    using SafeERC20 for IERC20Metadata;
    IFactory factory;

    error PoolNotFound(address tokenA, address tokenB);

    

    constructor(address _factory) {
        factory = IFactory(_factory);

    }

    struct exactMultiHopParams {
        uint amountInOrOut;
        address[] tokenPath;
        bool slippageProtecortion;
        uint targetAmountInOrOut;
        uint maxSlippagePercent;

    }

    function swapExactInMultiHop(address[] memory tokenPath, uint amountIn) public returns(uint) {
        uint hops = tokenPath.length;
        IERC20Metadata(tokenPath[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        // uint newAmountIn;
        for(uint i=0; i<hops -1; i++) {
            address pool = factory.getPool(tokenPath[i], tokenPath[i+1]);
            // custom error so you can know what tokens reverted
            if (pool == address(0)) revert PoolNotFound(tokenPath[i], tokenPath[i+1]);
            IERC20Metadata(tokenPath[i]).approve(pool, amountIn);
            // amountIn is the same as the output of the previous swap in the path
            amountIn = INSPool(pool).swapExactAmountIn(amountIn, tokenPath[i]);
        }

        IERC20Metadata(tokenPath[hops-1]).safeTransfer(msg.sender, amountIn);
    // again, amountIn is actually the amountOut of the last swap
        return amountIn;
    }

}