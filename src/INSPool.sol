pragma solidity 0.8.7;



interface INSPool {
    // using SafeERC20 for IERC20Metadata;
    // using PRBMath for uint;

    // address public tokenA;
    // address public tokenB;

    // mapping(address => uint) public tokenToInternalBalance;

    // bool public initialized;

    // modifier onlyPair(address token) {
    //     require(token == tokenA || token == tokenB);
    //     _;

    // }


    function name() external returns(string memory);

    function symbol() external returns (string memory);

    function tokenA() external returns(address);

    function tokenB() external returns(address);

    function initializePool(uint amountA, uint amountB) external;

    function getBalances() external view returns(uint balanceA, uint balanceB);
    
    function getLiquidityAmount(address token, uint amount) external view returns(address otherToken, uint otherAmount);

    function addLiquidity(address token, uint amount) external;

    function removeLiquidity(uint amount) external;

    function totalLiquidity() external view returns(uint);

    function getTokenAndAmountIn(address tokenOut, uint amountOut) external view returns (address tokenIn, uint amountIn);

    function getTokenAndAmountOut(address tokenIn, uint amountIn) external view returns(address tokenOut, uint amountOut);

    function swapExactAmountOut(uint amountOut, address tokenOut) external returns(uint);

    function swapExactAmountIn(uint amountIn, address tokenIn) external returns (uint);

    function swapExactOutWithSlippageProtection(uint targetAmountIn, uint amountOut, address tokenOut, uint maxBadSlippagePercent) external;

    function swapExactInWithSlippageProtection(uint targetAmountOut, uint amountIn,  address tokenIn, uint maxBadSlippagePercent) external;



}