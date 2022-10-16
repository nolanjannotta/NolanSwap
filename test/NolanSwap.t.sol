// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/NolanSwap.sol";
import "../src/MockERC20.sol";
import "forge-std/console.sol";




contract NolanSwapTest is Test {
    NolanSwap public nolanSwap;
    MockERC20 public schruteBucks;
    MockERC20 public stanleyNickels;

    function setUp() public {
       schruteBucks = new MockERC20("Schrute Bucks", "SCHRUTE");
       stanleyNickels = new MockERC20("Stanley Nickels", "STANLEY");
       nolanSwap = new NolanSwap(address(schruteBucks), address(stanleyNickels), "Nolan Swap", "NSWAP");
       schruteBucks.approve(address(nolanSwap), 2000 ether);
       stanleyNickels.approve(address(nolanSwap), 2000 ether);

    }

    function testLPTokenNameAndSymbol() public {
        assertEq(nolanSwap.name(), "SCHRUTE/STANLEY_LP_Tokens");
        assertEq(nolanSwap.symbol(), "SCHRUTE/STANLEY_LP");
    }

    function testMocks() public {
        assertEq(schruteBucks.balanceOf(address(this)), 2000 ether);
        assertEq(stanleyNickels.balanceOf(address(this)), 2000 ether);
    }

    function testTokens() public {
        assertEq(nolanSwap.tokenA(), address(schruteBucks));
        assertEq(nolanSwap.tokenB(), address(stanleyNickels));

    }

    function testInitializePool() public {
        nolanSwap.initializePool(1000 ether, 2000 ether);
        // schrutebucks = 1000 
        // stanleyNickels = 2000

    }

    function testAmountOut() public {
        nolanSwap.initializePool(1000 ether, 1000 ether);

        (,uint amountOut) = nolanSwap.getTokenAndAmountOut(address(schruteBucks), 50 ether); 
        // console.log(nolanSwap.totalLiquidity());
        // console.log(amountOut);

    }
    function testAmountIn() public {
        nolanSwap.initializePool(2000 ether, 2000 ether);
        (,uint amountIn) = nolanSwap.getTokenAndAmountIn(address(stanleyNickels), 1000 ether);
        // console.log(nolanSwap.totalLiquidity());
        // console.log(amountIn);

    }

    function testTotalLiquidity() public {
        nolanSwap.initializePool(2000 ether, 2000 ether);
        nolanSwap.totalLiquidity();
    }

    function testswapExactAmountOut() public {
        // lets swap x schruteBucks for 1000 stanleyNickels
        // tokenA = schruteBucks
        // tokenB = stanleyNickels
        uint swapAmount = 50 ether;
        // initialize pool
        nolanSwap.initializePool(1000 ether, 1000 ether); 
        console.log(nolanSwap.totalSupply());   
        // get the balance of this each token for this contract before the swap    
        uint schruteBalance = schruteBucks.balanceOf(address(this));
        uint stanleyBalance = stanleyNickels.balanceOf(address(this));
        // console.log(stanleyBalance,schruteBalance);
        // console.log(nolanSwap.totalLiquidity());

        // get the amountIn of other token required for an amountOut of other token
        // for approvals
        (,uint amountIn) = nolanSwap.getTokenAndAmountIn(address(stanleyNickels), swapAmount);
        schruteBucks.approve(address(nolanSwap), amountIn);
        // swap
        nolanSwap.swapExactAmountOut(swapAmount, nolanSwap.tokenB());

        // get and logs balance after
        assertEq(schruteBalance - amountIn, schruteBucks.balanceOf(address(this)));
        assertEq(stanleyBalance + swapAmount, stanleyNickels.balanceOf(address(this)));

        // schruteBalance = schruteBucks.balanceOf(address(this));
        // stanleyBalance = stanleyNickels.balanceOf(address(this));

        // console.log(stanleyBalance,schruteBalance);
        // console.log(nolanSwap.totalLiquidity());
        // console.log(nolanSwap.totalSupply());

    }
    function testSwapExactAmountIn() public {
        // lets swap 50 schruteBucks for x stanleyNickels
        // tokenA = schruteBucks
        // tokenB = stanleyNickels
        uint swapAmount = 50 ether;

        // initialize pool
        nolanSwap.initializePool(1000 ether, 1000 ether); 

        // get the balance of this each token for this contract before the swap    
        uint stanleyBalance = stanleyNickels.balanceOf(address(this));
        uint schruteBalance = schruteBucks.balanceOf(address(this));
        // console.log(stanleyBalance,schruteBalance);
        // console.log(nolanSwap.totalLiquidity());
    
        (,uint amountOut) = nolanSwap.getTokenAndAmountOut(address(stanleyNickels), swapAmount);
        schruteBucks.approve(address(nolanSwap), swapAmount);
        // swap
        nolanSwap.swapExactAmountIn(swapAmount, nolanSwap.tokenA());
        
        assertEq(schruteBalance - swapAmount, schruteBucks.balanceOf(address(this)));
        assertEq(stanleyBalance + amountOut, stanleyNickels.balanceOf(address(this)));

    }

    function testAddLiquidity() public {
        nolanSwap.initializePool(1000 ether, 700 ether);
        console.log(nolanSwap.totalSupply());  
        console.log(nolanSwap.totalLiquidity());  
 

    }

}
