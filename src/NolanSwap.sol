pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "prb-math/PRBMath.sol";



contract NolanSwap is ERC20 {
    using SafeERC20 for IERC20Metadata;
    using PRBMath for uint;

    address immutable public tokenA;
    address immutable public tokenB;

    mapping(address => uint) public tokenToInternalBalance;

    bool initialized;

    event PoolInitialized();
    event Swap();
    event IncreaseLiquidity();
    event DecreaseLiquidity();



    error AlreadyInitialized();


    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) 
    
        ERC20(
            string(abi.encodePacked(IERC20Metadata(_tokenA).symbol(), "/",IERC20Metadata(_tokenB).symbol(), "_LP_Tokens")), 
            string(abi.encodePacked(IERC20Metadata(_tokenA).symbol(), "/",IERC20Metadata(_tokenB).symbol(), "_LP"))
            ) {
        require(_tokenA != address(0) && _tokenB != address(0));
        // set tokenA and tokenB on deploy
        tokenA = _tokenA;
        tokenB = _tokenB;
    }


    function initializePool(uint amountA, uint amountB) public {
        // called once to add initial liquidity to pool
        if (initialized) revert AlreadyInitialized();
        initialized = true;
        // transfer tokenA, update internal balance
        IERC20Metadata(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        tokenToInternalBalance[tokenA] += amountA;
        // transfer tokenB, update internal balance
        IERC20Metadata(tokenB).safeTransferFrom(msg.sender, address(this), amountB);
        tokenToInternalBalance[tokenB] += amountB;
        // mint shares
        _mint(msg.sender, totalLiquidity());
        emit PoolInitialized();
        


    }
    
    // create public function returning amount of other token to add, for frontend

    function addLiquidity(address token, uint amount) public {
        address otherToken = getOtherToken(token);
        uint ratio = tokenToInternalBalance[otherToken] / tokenToInternalBalance[token];
        uint otherAmount = amount * ratio;

        IERC20Metadata(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Metadata(otherToken).safeTransferFrom(msg.sender, address(this), otherAmount);
        uint mint = ((otherAmount * amount).sqrt() / totalLiquidity()) * totalSupply();
        _mint(msg.sender,mint);
        tokenToInternalBalance[otherToken] += otherAmount;
        tokenToInternalBalance[token] += amount;
        emit IncreaseLiquidity();
    }

    function removeLiquidity(uint amount) public {
        uint tokenAAmount = tokenToInternalBalance[tokenA] * (amount / totalSupply());
        uint tokenBAmount = tokenToInternalBalance[tokenB] * (amount / totalSupply());

        _burn(msg.sender, amount);
        IERC20(tokenA).transfer(msg.sender, tokenAAmount);
        IERC20(tokenB).transfer(msg.sender, tokenBAmount);
        emit DecreaseLiquidity();
    }

    function totalLiquidity() public view returns(uint) {
        return (tokenToInternalBalance[tokenA] * tokenToInternalBalance[tokenB]).sqrt();
    }

    function getOtherToken(address token) internal view returns(address) {
        return token == tokenB ? tokenA : tokenB;
    }


    // dx = (X*dy) / (Y - dy)
    function getTokenAndAmountIn(address tokenOut, uint amountOut) public view returns (address tokenIn, uint amountIn) {
        tokenIn = getOtherToken(tokenOut);
        
        

        uint num = tokenToInternalBalance[tokenIn] * amountOut;
        uint den = tokenToInternalBalance[tokenOut] - amountOut;

        // amountIn = tokenToInternalBalance[tokenIn].mulDiv(amountOut,den);
        amountIn = num / den;

    }

    // dy = (Y*dx) / (X + dx)
    function getTokenAndAmountOut(address tokenIn, uint amountIn) public view returns(address tokenOut, uint amountOut) {
        tokenOut = getOtherToken(tokenIn); 
        uint num = tokenToInternalBalance[tokenOut] * amountIn;
        uint den = tokenToInternalBalance[tokenIn] + amountIn;
        
        // amountOut = tokenToInternalBalance[tokenOut].mulDiv(amountIn,den);
        amountOut = num /den;

    }

    function swapExactAmountOut(uint amountOut, address tokenOut) public { 
        require(tokenOut == address(tokenA) || tokenOut == address(tokenB));       
        (address tokenIn, uint amountIn) = getTokenAndAmountIn(tokenOut, amountOut);
        IERC20Metadata(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        tokenToInternalBalance[tokenIn] += amountIn;
        IERC20Metadata(tokenOut).safeTransfer( msg.sender, amountOut);
        tokenToInternalBalance[tokenOut] -= amountOut;
        emit Swap();


    }


    function swapExactAmountIn(uint amountIn, address tokenIn) public {
        require(tokenIn == tokenA || tokenIn == tokenB);
        (address tokenOut, uint amountOut) = getTokenAndAmountOut(tokenIn, amountIn);
        IERC20Metadata(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        tokenToInternalBalance[tokenIn] += amountIn;

        IERC20Metadata(tokenOut).safeTransfer(msg.sender, amountOut);
        tokenToInternalBalance[tokenOut] -= amountOut;
        emit Swap();
    }

}