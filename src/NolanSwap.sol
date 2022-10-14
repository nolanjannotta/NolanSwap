pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";



contract NolanSwap is ERC20 {

    using Math for uint;
    address immutable public tokenA;
    address immutable public tokenB;

    mapping(address => uint) public tokenToInternalBalance;

    bool initialized;

    error AlreadyInitialized();


    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }


    function initializePool(uint amountA, uint amountB) public {
        if (initialized) revert AlreadyInitialized();

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA));
        tokenToInternalBalance[tokenA] += amountA;

        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB));
        tokenToInternalBalance[tokenB] += amountB;

        initialized = true;


    }

    function addLiquidity() public {
        // do stuff
    }

    function removeLiquidity() public {

    }

    function totalLiquidity() public view returns(uint) {
        return (tokenToInternalBalance[tokenA] * tokenToInternalBalance[tokenB]).sqrt();
    }



    // dx = (X*dy) / (Y - dy)
    function getTokenAndAmountIn(address tokenOut, uint amountOut) public view returns (address tokenIn, uint amountIn) {
        tokenIn = tokenOut == tokenB ? tokenA : tokenB;
        uint num = tokenToInternalBalance[tokenIn] * amountOut;
        uint den = tokenToInternalBalance[tokenOut] - amountOut;
        amountIn = num / den;

    }

    // dy = (Y*dx) / (X + dx)
    function getTokenAndAmountOut(address tokenIn, uint amountIn) public view returns(address tokenOut, uint amountOut) {
        tokenOut = tokenIn == tokenA ? tokenB : tokenA; 
        uint num = tokenToInternalBalance[tokenOut] * amountIn;
        uint den = tokenToInternalBalance[tokenIn] + amountIn;

        amountOut = num / den;

    }

    function swapExactAmountOut(uint amountOut, address tokenOut) public {        
        (address tokenIn, uint amountIn) = getTokenAndAmountIn(tokenOut, amountOut);
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn));
        require(IERC20(tokenOut).transfer( msg.sender, amountOut));


    }


    function swapExactAmountIn(uint amountIn, address tokenIn) public {
        (address tokenOut, uint amountOut) = getTokenAndAmountOut(tokenIn, amountIn);
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn));
        require(IERC20(tokenOut).transfer(msg.sender, amountOut));
    }

}