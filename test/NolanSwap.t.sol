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
        uint swapAmountOut = 2 ether;
        address tokenOut = nolanSwap.tokenA();
        // initialize pool
        // 20:1 ration
        nolanSwap.initializePool(1000 ether, 50 ether); 
        // get the balance of this each token for this contract before the swap    
        

        // get the amountIn of other token required for an amountOut of other token
        // for approvals

        (,uint amountIn) = nolanSwap.getTokenAndAmountIn(tokenOut, swapAmountOut);
        schruteBucks.approve(address(nolanSwap), amountIn);
        
        uint schruteBalance = schruteBucks.balanceOf(address(this));
        uint stanleyBalance = stanleyNickels.balanceOf(address(this));
        

        // were swapping 'amountIn' of tokenB for 2 tokenA
        nolanSwap.swapExactAmountOut(swapAmountOut, nolanSwap.tokenA());
        
        
        // get and logs balance after
        // we should be receiving 'swapAmountOut', and sending 'amountIn'
        assertEq(schruteBalance + swapAmountOut, schruteBucks.balanceOf(address(this)));
        assertEq(stanleyBalance - amountIn, stanleyNickels.balanceOf(address(this)));


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

    function testLiquidityAmount() public {
        nolanSwap.initializePool(1000 ether, 500 ether);
        // since the ratio of tokenA to tokenB is 2:1, if we want to add 200 tokenAs (scruteBucks)
        // we should also add 100 tokenBs (stanleyNickels), (same ratio) 

        (address otherToken, uint amount) = nolanSwap.getLiquidityAmount(address(schruteBucks), 200 ether);
        assertEq(amount, 100 ether);

        // for 500 stanleyNickels we should receive 1000 schruteBucks
        (address _otherToken, uint _amount) = nolanSwap.getLiquidityAmount(address(stanleyNickels), 500 ether);
        assertEq(_amount, 1000 ether);



    }

    function testAddLiquidity() public {
        // initialize pool at 2:1 (tokenA:tokenB) ratio of tokens, 
        nolanSwap.initializePool(2000 ether, 1000 ether);

        // impersonate a new address
        vm.startPrank(address(0xBEEF));

        // mint tokens to our new address
        schruteBucks.mint(2000 ether);
        stanleyNickels.mint(2000 ether);
        assertEq(schruteBucks.balanceOf(address(0xBEEF)), 2000 ether);        
        assertEq(stanleyNickels.balanceOf(address(0xBEEF)), 2000 ether);

        // approve our swap
        stanleyNickels.approve(address(nolanSwap), 1000 ether);
        schruteBucks.approve(address(nolanSwap), 1000 ether);

        // lets add 300 schrutebucks(tokenA). we should also add 150 tokenB(stanleyNickels)
        nolanSwap.addLiquidity(address(schruteBucks), 300 ether);
        vm.stopPrank();
        (uint balanceA, uint balanceB) = nolanSwap.getBalances();
        assertEq(balanceA, 2300 ether);
        assertEq(balanceB, 1150 ether);
         

    }

    function testAddLiquidityAgain() public {
        // 10:1 ratio
        nolanSwap.initializePool(1000 ether, 100 ether);

        vm.startPrank(address(0xBEEF));

        // mint tokens to our new address
        schruteBucks.mint(2000 ether);
        stanleyNickels.mint(2000 ether);
        assertEq(schruteBucks.balanceOf(address(0xBEEF)), 2000 ether);        
        assertEq(stanleyNickels.balanceOf(address(0xBEEF)), 2000 ether);

        // approve our swap
        stanleyNickels.approve(address(nolanSwap), 1000 ether);
        schruteBucks.approve(address(nolanSwap), 1000 ether);

        // lets add 15 stankleyNickels(tokenB). we should also add 150 tokenA(schruteBucks)
        nolanSwap.addLiquidity(address(stanleyNickels), 15 ether);
        vm.stopPrank();
        (uint balanceA, uint balanceB) = nolanSwap.getBalances();
        assertEq(balanceA, 1150 ether);
        assertEq(balanceB, 115 ether);
         



    }

}
