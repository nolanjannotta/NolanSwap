pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 

import "@openzeppelin/contracts/utils/math/Math.sol";
import "prb-math/PRBMath.sol";
import "./ERC20Initializeable.sol";
import "solmate/utils/FixedPointMathLib.sol";



contract NSPoolStandard is ERC20 {

    using SafeERC20 for IERC20Metadata;
    using PRBMath for uint;
    // using FixedPointMathLib for uint;

    address public tokenA;
    address public tokenB;

    address public factory;
    mapping(address => uint) public tokenToInternalBalance;

    uint public fee;

    // bool public initialized;

    modifier onlyPair(address token) {
        require(token == tokenA || token == tokenB);
        _;

    }

    event PoolInitialized();
    event Swap();
    event IncreaseLiquidity(uint mint, uint amount, uint otherAmount);
    event DecreaseLiquidity();



    error AlreadyInitialized();


    constructor(address _tokenA, address _tokenB) ERC20(
            string(abi.encodePacked(IERC20Metadata(_tokenA).symbol(), "/",IERC20Metadata(_tokenB).symbol(), "_LP_Tokens")), 
            string(abi.encodePacked(IERC20Metadata(_tokenA).symbol(), "/",IERC20Metadata(_tokenB).symbol(), "_LP"))) {
            require(_tokenA != address(0) && _tokenB != address(0));
            // set tokenA and tokenB on deploy
            tokenA = _tokenA;
            tokenB = _tokenB;
            factory = msg.sender;
            fee = 3; // represents .3%

    }


    function initializePool(uint amountA, uint amountB) public {
        // called once to add initial liquidity to pool
        require(!initialized(), "already Initialized");
        // initialized = true;
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

    function setFee(uint newFee) public {
        require(msg.sender == factory, "Only factory");
        fee = newFee;

    }

    function getBalances() public view returns(uint balanceA, uint balanceB) {
        balanceA = tokenToInternalBalance[tokenA];
        balanceB = tokenToInternalBalance[tokenB];

    }

    // ---------------------------------------------------------------------------------
    //                                      helpers
    
    function initialized() public view returns(bool) {
        return (tokenToInternalBalance[tokenA] != 0 && tokenToInternalBalance[tokenB] != 0);
    }


    function getLiquidityAmount(address token, uint amount) public view returns(address otherToken, uint otherAmount) {
        otherToken = getOtherToken(token);
        uint ratio = tokenToInternalBalance[otherToken].mulDiv(1 ether, tokenToInternalBalance[token]);
        otherAmount = (amount * ratio) / 1 ether;
    }
    function getOtherToken(address token) internal view returns(address) {
        return token == tokenB ? tokenA : tokenB;
    }
    // ---------------------------------------------------------------------------------


    function addLiquidity(address token, uint amount) public {
        (address otherToken, uint otherAmount) = getLiquidityAmount(token,amount);

        IERC20Metadata(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Metadata(otherToken).safeTransferFrom(msg.sender, address(this), otherAmount);

        uint mint = ((otherAmount * amount).sqrt() * totalSupply()) / totalLiquidity();
        _mint(msg.sender,mint);
        tokenToInternalBalance[otherToken] += otherAmount;
        tokenToInternalBalance[token] += amount;
        emit IncreaseLiquidity(mint, amount, otherAmount);
    }

    function removeLiquidity(uint amount) public {
        uint tokenAAmount = (tokenToInternalBalance[tokenA] * amount) / totalSupply();
        uint tokenBAmount = (tokenToInternalBalance[tokenB] * amount) / totalSupply();

        _burn(msg.sender, amount);
        IERC20(tokenA).transfer(msg.sender, tokenAAmount);
        IERC20(tokenB).transfer(msg.sender, tokenBAmount);
        tokenToInternalBalance[tokenA] -= tokenAAmount;
        tokenToInternalBalance[tokenB] -= tokenBAmount;
        emit DecreaseLiquidity();
    }

    function totalLiquidity() public view returns(uint) {
        return (tokenToInternalBalance[tokenA] * tokenToInternalBalance[tokenB]).sqrt();
    }



    // dx = (X*dy) / (Y - dy)
    function getTokenAndAmountIn(address tokenOut, uint amountOut) public view returns (address tokenIn, uint amountIn) {
        tokenIn = getOtherToken(tokenOut);
        uint num = tokenToInternalBalance[tokenIn] * amountOut;
        uint den = tokenToInternalBalance[tokenOut] - amountOut;
        amountIn = num / den;
        // add fees:
        // since were providing the exact amount we want to receive, 
        // we need add the fee to the amount we need to send
        amountIn = amountIn * (1000 + fee) / 1000;

    }
        // dy = (Y*dx) / (X + dx)
    function getTokenAndAmountOut(address tokenIn, uint amountIn) public view returns(address tokenOut, uint amountOut) {
        tokenOut = getOtherToken(tokenIn); 
        uint num = tokenToInternalBalance[tokenOut] * amountIn;
        uint den = tokenToInternalBalance[tokenIn] + amountIn;        
        amountOut = num / den;
        // add fees:
        // since were specifying the exact amount we want to send,
        // we need to subtract the fee from the amount out, so we receive lightly less
        amountOut = amountOut * (1000 - fee) / 1000; // subtracts .3 percent

    }

    function _swap(address tokenIn, address tokenOut, uint amountIn, uint amountOut) private {
        IERC20Metadata(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);        
        tokenToInternalBalance[tokenIn] += amountIn;
        tokenToInternalBalance[tokenOut] -= amountOut;
        IERC20Metadata(tokenOut).safeTransfer(msg.sender, amountOut);
        
        emit Swap();
    }

    function swapExactAmountOut(uint amountOut, address tokenOut) public onlyPair(tokenOut) returns(uint) { 
        (address tokenIn, uint amountIn) = getTokenAndAmountIn(tokenOut, amountOut);
        _swap(tokenIn, tokenOut,amountIn,amountOut);
        return amountIn;

    }




    function swapExactAmountIn(uint amountIn, address tokenIn) public onlyPair(tokenIn) returns (uint){
        (address tokenOut, uint amountOut) = getTokenAndAmountOut(tokenIn, amountIn);
        _swap(tokenIn, tokenOut,amountIn,amountOut);
        return amountOut;
    }

    // these functions protect users from bad slippage

    // protects users from sending more than expected for receiving `amountOut` tokens
    function swapExactOutWithSlippageProtection(uint targetAmountIn, uint amountOut, address tokenOut, uint maxBadSlippagePercent) public {
        (address tokenIn, uint amountIn) = getTokenAndAmountIn(tokenOut, amountOut);
        uint highestAmountIn = targetAmountIn + ((targetAmountIn * maxBadSlippagePercent) / 100);
        require(amountIn <= highestAmountIn,"bad price");
        _swap(tokenIn, tokenOut,amountIn,amountOut);        
    }

    
    // protects users from receiving less than expected for `amountIn` tokens
    function swapExactInWithSlippageProtection(uint targetAmountOut, uint amountIn,  address tokenIn, uint maxBadSlippagePercent) public {
        (address tokenOut, uint amountOut) = getTokenAndAmountOut(tokenIn, amountIn);
        uint lowestAmountOut = targetAmountOut - ((targetAmountOut * maxBadSlippagePercent) / 100);
        require(amountOut >= lowestAmountOut, "bad price");
        _swap(tokenIn, tokenOut,amountIn,amountOut);
        
    }



}
