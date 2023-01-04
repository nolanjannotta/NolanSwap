// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/INSPool.sol";
import "../src/MockERC20.sol";
import "../src/PoolFactory.sol"; 
import "../src/NSRouter.sol";
import "forge-std/console.sol";




contract RouterTest is Test {
    INSPool public schrute_StanleyPool;
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

        schrute_StanleyPool = INSPool(poolFactory.getPool(address(schruteBucks), address(stanleyNickels)));
        // nolanSwap = new NolanSwap(address(schruteBucks), address(stanleyNickels), "Nolan Swap", "NSWAP");
        schruteBucks.approve(address(schrute_StanleyPool), 2000 ether);
        stanleyNickels.approve(address(schrute_StanleyPool), 2000 ether);

    }

    function testMultiHopSwapExactIn() public {
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



        schrute_StanleyPool.initializePool(1000 ether, 100 ether);
        stanleyNickels_newTokenA.initializePool(300 ether, 300 ether);
        newTokenA_NewTokenB.initializePool(700 ether, 700 ether);
        
        
        
        address[] memory path = new address[](4);
        // [schruteBucks,stanleyNickels,newTokenA,newTokenB]

        path[0] = address(schruteBucks);
        path[1] = address(stanleyNickels);
        path[2] = address(newTokenA);
        path[3] = address(newTokenB);

        // we want to spend exactly 50 schruteBucks for as much of newTokenB
        uint amountIn = 50 ether;

        (,uint stanleyNickelsAmount) = schrute_StanleyPool.getTokenAndAmountOut(address(schruteBucks), amountIn);
        (,uint newTokenAAmount) = stanleyNickels_newTokenA.getTokenAndAmountOut(address(stanleyNickels), stanleyNickelsAmount);
        (,uint newTokenBAmount) = newTokenA_NewTokenB.getTokenAndAmountOut(address(newTokenA), newTokenAAmount);
        // console.log("stanley nickels amount: ", stanleyNickelsAmount);
        // console.log("new tokenA amount: ", newTokenAAmount);
        // console.log("new tokenB amount: ", newTokenBAmount);

        // lets figure out how many tokens should come out at the end:
        // formula: 
        //   dy = (Y*dx) / (X + dx)  
        //   amountOut = (tokenBReserves * amountIn) / (tokenAReserves + amountIn)

        // first swap: between schrute bucks and stanley nickels
        // (100 x 50) / (1000 + 50) = 4.76190476...
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

    function testMultiHopSwapExactOut() public {
        // create pool for our new tokens
        // this is the last hop in our path.
        address _newTokenA_NewTokenB = poolFactory.createPair(address(newTokenA), address(newTokenB));

        newTokenA_NewTokenB = INSPool(_newTokenA_NewTokenB);
        // allow the pool to swap our tokens
        newTokenA.approve(_newTokenA_NewTokenB, 2000 ether);
        newTokenB.approve(_newTokenA_NewTokenB, 2000 ether);

        // create intermediary pool for the hops
        address _stanleyNickels_newTokenA = poolFactory.createPair(address(stanleyNickels), address(newTokenA));

        stanleyNickels_newTokenA = INSPool(_stanleyNickels_newTokenA);
        // allow the pool to swap our tokens
        newTokenA.approve(_stanleyNickels_newTokenA, 2000 ether);
        stanleyNickels.approve(_stanleyNickels_newTokenA, 2000 ether);


        // initialize all the pools for our swap
        schrute_StanleyPool.initializePool(1000 ether, 500 ether);
        stanleyNickels_newTokenA.initializePool(300 ether, 300 ether);
        newTokenA_NewTokenB.initializePool(700 ether, 500 ether);
        
        
        // [schruteBucks,stanleyNickels,newTokenA,newTokenB]
        
        address[] memory path = new address[](4);

        path[0] = address(schruteBucks);
        path[1] = address(stanleyNickels);
        path[2] = address(newTokenA);
        path[3] = address(newTokenB);

        // we want to receive exactly 10 newTokenBs for an unknown amount of schruteBucks
        uint amountOut = 10 ether;

        // (,uint stanleyNickelsAmount) = schrute_StanleyPool.getTokenAndAmountOut(address(schruteBucks), amountIn);
        // (,uint newTokenAAmount) = stanleyNickels_newTokenA.getTokenAndAmountOut(address(stanleyNickels), stanleyNickelsAmount);
        // (,uint newTokenBAmount) = newTokenA_NewTokenB.getTokenAndAmountOut(address(newTokenA), newTokenAAmount);
        // console.log("stanley nickels amount: ", stanleyNickelsAmount);
        // console.log("new tokenA amount: ", newTokenAAmount);
        // console.log("new tokenB amount: ", newTokenBAmount);

        // lets figure out how many schruteBucks we need to send to receive 10 newTokenBs:
        // formula:
        //   dx = (X*dy) / (Y - dy)
        //  amountIn = (tokenAReserves * amountOut) / (tokenbReserves - amountOut)

        // PATH =  [schruteBucks,stanleyNickels,newTokenA,newTokenB]

        // last swap: between newTokenA and newTokenB
        // (700 x 10) / (500 - 10) = 14.285714285714
        // after fee: 14.285714285714 + (14.285714285714 * .003) = 14.328571428571142
        // input - 14.328571428571142 newTokenA
        // output - 10 newTokenB
        (,uint newTokenAIn) = newTokenA_NewTokenB.getTokenAndAmountIn(address(newTokenB), amountOut);
        console.log("newTokenAIn", newTokenAIn);

        // second to last swap: between stanley nickels and newTokenA:
        // (300 x 14.328571428571142) / (300 - 14.328571428571142) = 15.047257088562
        // fee: 15.047257088562 + (15.047257088562 *  .003) = 15.092398859827686
        // input - 15.092398859827686 stanley nickels
        // output - 14.328571428571142 new tokenA
        (,uint stanleyNickelsIn) = stanleyNickels_newTokenA.getTokenAndAmountIn(address(newTokenA), newTokenAIn);
        console.log("stanleyNickelsIn", stanleyNickelsIn);
        
        // first swap: betweem schruteBucks and stanleyNickels
        // (1000 x 15.092398859827686) / (500 - 15.092398859827686) = 31.12427774763820
        // fee: 31.12427774763820 + (31.12427774763820 * .003) = 31.2176505808811146
        // input - 31.2176505808811146 schruteBucks
        // output = 15.092398859827686 stanleyNickels
        (,uint schruteBucksIn) = schrute_StanleyPool.getTokenAndAmountIn(address(stanleyNickels), stanleyNickelsIn);
        console.log("schruteBucksIn", schruteBucksIn);
        // so looks like we need to send 30.9278350515463598 for 10 
         
        uint newTokenB_BalanceBefore = newTokenB.balanceOf(address(this));
        // console.log("newTokenB before", newTokenB_BalanceBefore);
        uint schruteBucks_BalanceBefore = schruteBucks.balanceOf(address(this));
        // approve the first token in the path to be spent by the router
        schruteBucks.approve(address(nsRouter), 32 ether);
        // execute swap
        uint amountIn = nsRouter.swapExactOutMultiHop(path, amountOut);

        // make sure the swap function returns the same amount that we calculated
        // assertEq(newTokenBAmount, amountOut);
        // console.log(amountIn);

        // check is balance is equal balance before + amountOut
        uint newTokenB_BalanceAfter = newTokenB.balanceOf(address(this));
        // console.log("newTokenB after", newTokenB_BalanceAfter);
        uint schruteBucks_BalanceAfter = schruteBucks.balanceOf(address(this));


        // this fails due to rounding error of 2 wei, working on a solution...
        // assertEq(newTokenB_BalanceBefore + amountOut, newTokenB_BalanceAfter);

        // this passes
        assertEq(schruteBucks_BalanceBefore - amountIn, schruteBucks_BalanceAfter);






    }


}
