// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/INSPool.sol";
import "../src/MockERC20.sol";
import "../src/PoolFactory.sol"; 
import "../src/NSRouter.sol";
import "forge-std/console.sol";




contract NolanSwapTest is Test {
    INSPool public schrute_Stanley;
    INSPool public newTokenA_NewTokenB;
    INSPool public stanleyNickels_newTokenA;

    // tokens for us to swap
    MockERC20 public schruteBucks;
    MockERC20 public stanleyNickels;

    MockERC20 public newTokenA;
    MockERC20 public newTokenB;

    PoolFactory public poolFactory;
    NSRouter public nsRouter;

    function setUp() public {
        schruteBucks = new MockERC20("Schrute Bucks", "SCHRUTE");
        stanleyNickels = new MockERC20("Stanley Nickels", "STANLEY");

        newTokenA = new MockERC20("Token A", "tokenA");
        newTokenB = new MockERC20("Token B", "tokenB");
        poolFactory = new PoolFactory();
        nsRouter = new NSRouter(address(poolFactory));
        poolFactory.createPair(address(schruteBucks), address(stanleyNickels));

        schrute_Stanley = INSPool(poolFactory.getPool(address(schruteBucks), address(stanleyNickels)));
        // nolanSwap = new NolanSwap(address(schruteBucks), address(stanleyNickels), "Nolan Swap", "NSWAP");
        schruteBucks.approve(address(schrute_Stanley), 2000 ether);
        stanleyNickels.approve(address(schrute_Stanley), 2000 ether);

    }

    function testLPTokenNameAndSymbol() public {
        assertEq(schrute_Stanley.name(), "SCHRUTE/STANLEY_LP_Tokens");
        assertEq(schrute_Stanley.symbol(), "SCHRUTE/STANLEY_LP");
    }

    function testMocks() public {
        assertEq(schruteBucks.balanceOf(address(this)), 2000 ether);
        assertEq(stanleyNickels.balanceOf(address(this)), 2000 ether);
    }

    function testTokens() public {
        assertEq(schrute_Stanley.tokenA(), address(schruteBucks));
        assertEq(schrute_Stanley.tokenB(), address(stanleyNickels));

    }

    function testInitializePool() public {
        schrute_Stanley.initializePool(1000 ether, 2000 ether);
        // schrutebucks = 1000 
        // stanleyNickels = 2000

    }

    function testAmountOut() public {
        schrute_Stanley.initializePool(1000 ether, 1000 ether);

        (,uint amountOut) = schrute_Stanley.getTokenAndAmountOut(address(schruteBucks), 50 ether); 


    }
    function testAmountIn() public {
        schrute_Stanley.initializePool(2000 ether, 2000 ether);
        (,uint amountIn) = schrute_Stanley.getTokenAndAmountIn(address(stanleyNickels), 1000 ether);


    }

    // SWAP TESTS

    function testswapExactAmountOut() public {
        // lets swap x schruteBucks for 1000 stanleyNickels
        // tokenA = schruteBucks
        // tokenB = stanleyNickels
        uint swapAmountOut = 2 ether;
        address tokenOut = schrute_Stanley.tokenA();
        // initialize pool
        // 20:1 ration
        schrute_Stanley.initializePool(1000 ether, 50 ether); 
        // get the balance of this each token for this contract before the swap    
        

        // get the amountIn of other token required for an amountOut of other token
        // for approvals

        (,uint amountIn) = schrute_Stanley.getTokenAndAmountIn(tokenOut, swapAmountOut);
        schruteBucks.approve(address(schrute_Stanley), amountIn);
        
        uint schruteBalance = schruteBucks.balanceOf(address(this));
        uint stanleyBalance = stanleyNickels.balanceOf(address(this));
        

        // were swapping 'amountIn' of tokenB for 2 tokenA
        schrute_Stanley.swapExactAmountOut(swapAmountOut, schrute_Stanley.tokenA());
        
        
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
        schrute_Stanley.initializePool(1000 ether, 1000 ether); 

        // get the balance of this each token for this contract before the swap    
        uint stanleyBalance = stanleyNickels.balanceOf(address(this));
        uint schruteBalance = schruteBucks.balanceOf(address(this));
        // console.log(stanleyBalance,schruteBalance);
        // console.log(nolanSwap.totalLiquidity());
    
        (,uint amountOut) = schrute_Stanley.getTokenAndAmountOut(address(stanleyNickels), swapAmount);
        schruteBucks.approve(address(schrute_Stanley), swapAmount);
        // swap
        schrute_Stanley.swapExactAmountIn(swapAmount, schrute_Stanley.tokenA());
        
        assertEq(schruteBalance - swapAmount, schruteBucks.balanceOf(address(this)));
        assertEq(stanleyBalance + amountOut, stanleyNickels.balanceOf(address(this)));

    }
    function testSwapExactAmountInWithSlippageProtection() public {
        // lets swap 50 schruteBucks for x stanleyNickels
        // tokenA = schruteBucks
        // tokenB = stanleyNickels
        uint swapAmountIn = 50 ether;
        uint targetAmountOut = 50 ether;
        uint maxPercent = 5;
        // so the minimum amount we want to receive is targetAmountOut - 5%

        uint worstPrice = targetAmountOut - ((targetAmountOut * maxPercent) / 100); // = 47500000000000000000
        console.log(worstPrice);
        // initialize pool 
        // 1:1 ratio
        schrute_Stanley.initializePool(1000 ether, 1000 ether); 

        // get the balance of this each token for this contract before the swap    
        uint stanleyBalance = stanleyNickels.balanceOf(address(this));
        uint schruteBalance = schruteBucks.balanceOf(address(this));
    
        (,uint amountOut) = schrute_Stanley.getTokenAndAmountOut(address(schruteBucks), swapAmountIn);
        console.log(amountOut);
        // amountOut == 47619047619047619047
        // worstPrice = 47500000000000000000
        // since amountOut is GREATER than the users worst acceptable price. this swap should work
        schruteBucks.approve(address(schrute_Stanley), swapAmountIn);
        // swap
        schrute_Stanley.swapExactInWithSlippageProtection(targetAmountOut, swapAmountIn, address(schruteBucks), maxPercent); 

        // lets try again with the same values
        (, amountOut) = schrute_Stanley.getTokenAndAmountOut(address(schruteBucks), swapAmountIn);
        // amountOut = 43290043290043290043
        // worstPrice = 47500000000000000000
        // since amountOut is now LESS than the users worst acceptable price. this swap should not work
        // schruteBalance = schruteBucks.balanceOf(address(this));

        schruteBucks.approve(address(schrute_Stanley), swapAmountIn);

        vm.expectRevert(bytes("bad price"));
        schrute_Stanley.swapExactInWithSlippageProtection(targetAmountOut, swapAmountIn, address(schruteBucks), maxPercent);

    }

    function testSwapExactAmountOutWithSlippageProtection() public {
        // lets swap x schruteBucks for 50 stanleyNickels
        // tokenA = schruteBucks
        // tokenB = stanleyNickels
        uint swapAmountOut = 50 ether;
        uint targetAmountIn = 50 ether;
        uint maxPercent = 5;
        // so the max amount we want to send is targetAmountIn + 5%

        uint worstPrice = targetAmountIn + ((targetAmountIn * maxPercent) / 100); // = 47500000000000000000
        console.log(worstPrice);
        // initialize pool 
        // 1:1 ratio
        schrute_Stanley.initializePool(1000 ether, 1000 ether); 

        // get the balance of this each token for this contract before the swap    
        uint stanleyBalance = stanleyNickels.balanceOf(address(this));
        uint schruteBalance = schruteBucks.balanceOf(address(this));
    
        (,uint amountOut) = schrute_Stanley.getTokenAndAmountIn(address(stanleyNickels), swapAmountOut);
        console.log(amountOut);
        // amountOut == 47619047619047619047
        // worstPrice = 47500000000000000000
        // since amountOut is GREATER than the users worst acceptable price. this swap should work
        schruteBucks.approve(address(schrute_Stanley), swapAmountOut);
        // swap
        schrute_Stanley.swapExactInWithSlippageProtection(targetAmountIn, swapAmountOut, address(stanleyNickels), maxPercent); 

        // lets try again with the same values
        (, amountOut) = schrute_Stanley.getTokenAndAmountOut(address(stanleyNickels), swapAmountOut);
        // amountOut = 43290043290043290043
        // worstPrice = 47500000000000000000
        // since amountOut is now LESS than the users worst acceptable price. this swap should not work
        // schruteBalance = schruteBucks.balanceOf(address(this));

        schruteBucks.approve(address(schrute_Stanley), swapAmountOut);

        vm.expectRevert(bytes("bad price"));
        schrute_Stanley.swapExactInWithSlippageProtection(targetAmountIn, swapAmountOut, address(stanleyNickels), maxPercent);

    }



    // LIQUIDITY RELATED TESTS
    function testTotalLiquidity() public {
        schrute_Stanley.initializePool(2000 ether, 2000 ether);
        schrute_Stanley.totalLiquidity();
    }

    function testLiquidityAmount() public {
        schrute_Stanley.initializePool(1000 ether, 500 ether);
        // since the ratio of tokenA to tokenB is 2:1, if we want to add 200 tokenAs (scruteBucks)
        // we should also add 100 tokenBs (stanleyNickels), (same ratio) 

        (, uint amount) = schrute_Stanley.getLiquidityAmount(address(schruteBucks), 200 ether);
        assertEq(amount, 100 ether);

        // for 500 stanleyNickels we should receive 1000 schruteBucks
        (, uint _amount) = schrute_Stanley.getLiquidityAmount(address(stanleyNickels), 500 ether);
        assertEq(_amount, 1000 ether);



    }

    function testAddLiquidity() public {
        // initialize pool at 2:1 (tokenA:tokenB) ratio of tokens, 
        schrute_Stanley.initializePool(2000 ether, 1000 ether);

        // impersonate a new address
        vm.startPrank(address(0xBEEF));

        // mint tokens to our new address
        schruteBucks.mint(2000 ether);
        stanleyNickels.mint(2000 ether);
        assertEq(schruteBucks.balanceOf(address(0xBEEF)), 2000 ether);        
        assertEq(stanleyNickels.balanceOf(address(0xBEEF)), 2000 ether);

        // approve our swap
        stanleyNickels.approve(address(schrute_Stanley), 1000 ether);
        schruteBucks.approve(address(schrute_Stanley), 1000 ether);

        // lets add 300 schrutebucks(tokenA). we should also add 150 tokenB(stanleyNickels)
        schrute_Stanley.addLiquidity(address(schruteBucks), 300 ether);
        vm.stopPrank();
        (uint balanceA, uint balanceB) = schrute_Stanley.getBalances();
        assertEq(balanceA, 2300 ether);
        assertEq(balanceB, 1150 ether);
         

    }

    function testAddLiquidityAgain() public {
        // 10:1 ratio
        schrute_Stanley.initializePool(1000 ether, 100 ether);

        vm.startPrank(address(0xBEEF));

        // mint tokens to our new address
        schruteBucks.mint(2000 ether);
        stanleyNickels.mint(2000 ether);
        assertEq(schruteBucks.balanceOf(address(0xBEEF)), 2000 ether);        
        assertEq(stanleyNickels.balanceOf(address(0xBEEF)), 2000 ether);

        // approve our swap
        stanleyNickels.approve(address(schrute_Stanley), 1000 ether);
        schruteBucks.approve(address(schrute_Stanley), 1000 ether);

        // lets add 15 stankleyNickels(tokenB). we should also add 150 tokenA(schruteBucks)
        schrute_Stanley.addLiquidity(address(stanleyNickels), 15 ether);
        vm.stopPrank();
        (uint balanceA, uint balanceB) = schrute_Stanley.getBalances();
        assertEq(balanceA, 1150 ether);
        assertEq(balanceB, 115 ether);
         



    }

    function testMultiHopSwap() public {
        // create pool for our new tokens
        // this is the last hop in our path.
        address _newTokenA_NewTokenB = poolFactory.createPair(address(newTokenA), address(newTokenB));
        newTokenA_NewTokenB = INSPool(_newTokenA_NewTokenB);
        newTokenA.approve(_newTokenA_NewTokenB, 2000 ether);
        newTokenB.approve(_newTokenA_NewTokenB, 2000 ether);

        // create intermediary pool for the hops
        address _stanleyNickels_newTokenA = poolFactory.createPair(address(stanleyNickels), address(newTokenA));
        stanleyNickels_newTokenA = INSPool(_stanleyNickels_newTokenA);
        newTokenA.approve(_stanleyNickels_newTokenA, 2000 ether);
        stanleyNickels.approve(_stanleyNickels_newTokenA, 2000 ether);



        schrute_Stanley.initializePool(1000 ether, 100 ether);
        stanleyNickels_newTokenA.initializePool(300 ether, 300 ether);
        newTokenA_NewTokenB.initializePool(700 ether, 700 ether);
        
        // [schruteBucks,stanleyNickels,newTokenA,newTokenB]
        
        address[] memory path = new address[](4);

        path[0] = address(schruteBucks);
        path[1] = address(stanleyNickels);
        path[2] = address(newTokenA);
        path[3] = address(newTokenB);

        uint amountIn = 50 ether;
        (,uint stanleyNickelsAmount) = schrute_Stanley.getTokenAndAmountOut(address(schruteBucks), amountIn);
        (,uint newTokenAAmount) = stanleyNickels_newTokenA.getTokenAndAmountOut(address(stanleyNickels), stanleyNickelsAmount);
        (,uint newTokenBAmount) = newTokenA_NewTokenB.getTokenAndAmountOut(address(newTokenA), newTokenAAmount);
        // console.log("stanley nickels amount: ", stanleyNickelsAmount);
        // console.log("new tokenA amount: ", newTokenAAmount);
        // console.log("new tokenB amount: ", newTokenBAmount);

        // lets figure out how many tokens should come out at the end:
        // formula: dy = (Y*dx) / (X + dx)

        // first swap: between schrute bucks and stanley nickels
        // (100 x 50) / (1000 + 50) = 4.76190476 -- 4761904761904761904
        // input - 50 schrute bucks
        // output - 4.76190476 stanley nickels

        // second swap: between stanley nickels and newTokenA:
        // (300 x 4.76190476) / (300 + 4.76190476) = 4.68749999815
        // input - 4.76190476 stanley nickels
        // output - 4.68749999815 new tokenA
        
        // third and last swap: betweem newTokenA and newTokenB
        // (700 x 4.68749999815) / (700 + 4.68749999815) = 4.656319288640
        // input - 4.68749999815 newTokenA
        // output = 4.656319288640 newTokenB

         
        uint newTokenB_BalanceBefore = newTokenB.balanceOf(address(this));
        // approve the first token in the path to be spent by the router
        schruteBucks.approve(address(nsRouter), amountIn);
        // execute swap
        uint amountOut = nsRouter.swapExactInMultiHop(path, amountIn);

        // make sure the swap function returns the same amount that we calculated
        assertEq(newTokenBAmount, amountOut);

        // check is balance is equal balance before + amountOut
        uint newTokenB_BalanceAfter = newTokenB.balanceOf(address(this));
        assertEq(newTokenB_BalanceBefore + newTokenBAmount, newTokenB_BalanceAfter);






    }


}
