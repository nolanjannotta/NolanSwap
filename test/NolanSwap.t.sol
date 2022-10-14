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
       schruteBucks.approve(address(nolanSwap), 10_000 ether);
       stanleyNickels.approve(address(nolanSwap), 10_000 ether);

    }

    function testMocks() public {
        assertEq(schruteBucks.balanceOf(address(this)), 10_000 ether);
        assertEq(stanleyNickels.balanceOf(address(this)), 10_000 ether);
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
        nolanSwap.initializePool(10000 ether, 5000 ether);

        (,uint amountOut) = nolanSwap.getTokenAndAmountOut(address(schruteBucks), 50 ether); 
        console.log(nolanSwap.totalLiquidity());
        console.log(amountOut);

    }
    function testAmountIn() public {
        nolanSwap.initializePool(10000 ether, 5000 ether);
        (,uint amountIn) = nolanSwap.getTokenAndAmountIn(address(stanleyNickels), 1000 ether);
        console.log(nolanSwap.totalLiquidity());
        console.log(amountIn);

    }

    function testTotalLiquidity() public {
        nolanSwap.initializePool(1000 ether, 5000 ether);
    }

    function testswapExactAmountOut() public {
        // lets swap x amount of schruteBucks for 1000 stanleyNickels
        // tokenA = schruteBucks
        // tokenB = stanleyNickels
        nolanSwap.initializePool(1000 ether, 5000 ether);        
        uint StanleyBalanceBefore = stanleyNickels.balanceOf(address(this));
        uint SchruteBalanceBefore = schruteBucks.balanceOf(address(this));
        console.log(StanleyBalanceBefore,SchruteBalanceBefore);
        (,uint amountIn) = nolanSwap.getTokenAndAmountIn(address(stanleyNickels), 100 ether);
        schruteBucks.approve(address(nolanSwap), amountIn);
        nolanSwap.swapExactAmountOut(100 ether, nolanSwap.tokenB());

    }

}