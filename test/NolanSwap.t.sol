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
    INSPool public newTokenA_newTokenB;
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


        // create pools:
        // test all of these!!!!!!!!!!

        // cloning
        schrute_Stanley = INSPool(poolFactory.createPairClone(address(schruteBucks), address(stanleyNickels)));
        newTokenA_newTokenB = INSPool(poolFactory.createPairClone(address(newTokenA), address(newTokenB)));


        // Create2
        // schrute_Stanley = INSPool(poolFactory.createPairCreate2(address(schruteBucks), address(stanleyNickels)));
        // newTokenA_newTokenB = INSPool(poolFactory.createPairCreate2(address(newTokenA), address(newTokenB)));
        
        // standard contract deploy
        // schrute_Stanley = INSPool(poolFactory.createPairStandard(address(schruteBucks), address(stanleyNickels)));
        // newTokenA_newTokenB = INSPool(poolFactory.createPairStandard(address(newTokenA), address(newTokenB)));





        // schrute_Stanley = INSPool(poolFactory.getPool(address(schruteBucks), address(stanleyNickels)));
        // nolanSwap = new NolanSwap(address(schruteBucks), address(stanleyNickels), "Nolan Swap", "NSWAP");
        schruteBucks.approve(address(schrute_Stanley), 2000 ether);
        stanleyNickels.approve(address(schrute_Stanley), 2000 ether);

        newTokenA.approve(address(newTokenA_newTokenB), 2000 ether);
        newTokenB.approve(address(newTokenA_newTokenB), 2000 ether);

    }

    function testOwner() public {
        assertEq(address(this), poolFactory.owner());

    }

    function testLPTokenNameAndSymbol() public {
        assertEq(schrute_Stanley.name(), "SCHRUTE/STANLEY_LP_Tokens");
        assertEq(schrute_Stanley.symbol(), "SCHRUTE/STANLEY_LP");
    }

    function testMocks() public {
        assertEq(schruteBucks.balanceOf(address(this)), 50_000 ether);
        assertEq(stanleyNickels.balanceOf(address(this)), 50_000 ether);
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

    function testInitializePoolIfBalanceAreZero() public {
        // if a pool is already initialized, but for some reason all liquidity has been removed,
        // this tests if a user can reinitialize the pool

        schrute_Stanley.initializePool(1000 ether, 1500 ether);
        uint totalLiquidity = schrute_Stanley.totalLiquidity();
        schrute_Stanley.removeLiquidity(totalLiquidity);
        uint totalLiquidityAfter = schrute_Stanley.totalLiquidity();

        (uint tokenAReserves, uint tokenBReserves) = schrute_Stanley.getBalances();
        assertEq(tokenAReserves,0);
        assertEq(tokenBReserves,0);
        assertEq(totalLiquidityAfter, 0);

        // since both reserves are zero, should be able to initialize again.

        schrute_Stanley.initializePool(50 ether, 20 ether);

        (tokenAReserves, tokenBReserves) = schrute_Stanley.getBalances();
        assertEq(tokenAReserves, 50 ether);
        assertEq(tokenBReserves, 20 ether);
        
        // since they are not zero, initializing again should revert
        vm.expectRevert(bytes("already Initialized"));
        schrute_Stanley.initializePool(50 ether, 20 ether);

    }

    function testAmountOut() public {
        schrute_Stanley.initializePool(1000 ether, 1000 ether);
        uint amountIn = 50 ether;


        (,uint amountOut) = schrute_Stanley.getTokenAndAmountOut(address(schruteBucks), amountIn); 
        // dy = (Y*dx) / (X + dx)  
        // (1000 * 50) / (1000 + 50) = 47.619047619047619047
        // fee: 47.619047619047619047 - (47.619047619047619047 * .003) = 47.476190476190476189
        assertEq(47476190476190476189, amountOut);
        


    }

    function testAmountIn() public {
        schrute_Stanley.initializePool(2000 ether, 300 ether);
        uint amountOut = 15 ether;
        (,uint amountIn) = schrute_Stanley.getTokenAndAmountIn(address(stanleyNickels), amountOut);
        // dx = (X*dy) / (Y - dy)
        // (2000 * 15) / (300 - 15) = 105.263157894736842105
        // fee: 105.263157894736842105 + (105.263157894736842105 * .003) = 105.578947368421052631
        assertEq(105578947368421052631, amountIn);

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

    function testSwapWithNotPairAddress() public {
        schrute_Stanley.initializePool(1000 ether, 50 ether); 
        vm.expectRevert();
        schrute_Stanley.swapExactAmountOut(1 ether, address(0xBEEF));


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
        uint maxPercent = 6;
        // so the minimum amount we want to receive is targetAmountOut - 5%

        uint worstPrice = targetAmountOut - ((targetAmountOut * maxPercent) / 100); // = 47500000000000000000
        console.log(worstPrice);
        // initialize pool 
        // 1:1 ratio
        schrute_Stanley.initializePool(1000 ether, 1000 ether); 

        // get the balance of this each token for this contract before the swap    
        uint stanleyBalanceBefore = stanleyNickels.balanceOf(address(this));
        uint schruteBalanceBefore = schruteBucks.balanceOf(address(this));
    
        (,uint amountOut) = schrute_Stanley.getTokenAndAmountOut(address(schruteBucks), swapAmountIn);
        console.log(amountOut);
        // amountOut == 47619047619047619047
        // worstPrice = 47500000000000000000
        // since amountOut is GREATER than the users worst acceptable price. this swap should work
        schruteBucks.approve(address(schrute_Stanley), swapAmountIn);
        // swap
        schrute_Stanley.swapExactInWithSlippageProtection(targetAmountOut, swapAmountIn, address(schruteBucks), maxPercent); 
        
        // make sure correct amounts are swapped
        uint stanleyBalanceAfter = stanleyNickels.balanceOf(address(this));
        uint schruteBalanceAfter = schruteBucks.balanceOf(address(this));
        assertEq(stanleyBalanceAfter, stanleyBalanceBefore + amountOut);
        assertEq(schruteBalanceAfter, schruteBalanceBefore - swapAmountIn);    



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
        uint maxPercent = 6;
        // so the max amount we want to send is targetAmountIn + 5%

        uint worstPrice = targetAmountIn + ((targetAmountIn * maxPercent) / 100); // = 47500000000000000000
        console.log(worstPrice);
        // initialize pool 
        // 1:1 ratio
        schrute_Stanley.initializePool(1000 ether, 1000 ether); 

        // get the balance of this each token for this contract before the swap    
        uint stanleyBalanceBefore = stanleyNickels.balanceOf(address(this));
        uint schruteBalanceBefore = schruteBucks.balanceOf(address(this));
    
        (,uint amountIn) = schrute_Stanley.getTokenAndAmountIn(address(stanleyNickels), swapAmountOut);
        console.log(amountIn);
        // amountOut == 47619047619047619047
        // worstPrice = 47500000000000000000
        // since amountOut is GREATER than the users worst acceptable price. this swap should work
        schruteBucks.approve(address(schrute_Stanley), amountIn);

        // swap
        schrute_Stanley.swapExactOutWithSlippageProtection(targetAmountIn, swapAmountOut, address(stanleyNickels), maxPercent); 

        // make sure correct amounts are swapped
        uint stanleyBalanceAfter = stanleyNickels.balanceOf(address(this));
        uint schruteBalanceAfter = schruteBucks.balanceOf(address(this));
        assertEq(stanleyBalanceAfter, stanleyBalanceBefore + swapAmountOut);
        assertEq(schruteBalanceAfter, schruteBalanceBefore - amountIn);    




        // lets try again with the same values
        (, amountIn) = schrute_Stanley.getTokenAndAmountOut(address(stanleyNickels), swapAmountOut);
        // amountOut = 43290043290043290043
        // worstPrice = 47500000000000000000
        // since amountOut is now LESS than the users worst acceptable price. this swap should not work
        // schruteBalance = schruteBucks.balanceOf(address(this));

        schruteBucks.approve(address(schrute_Stanley), amountIn);

        vm.expectRevert(bytes("bad price"));
        schrute_Stanley.swapExactOutWithSlippageProtection(targetAmountIn, swapAmountOut, address(stanleyNickels), maxPercent);

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

    function testFees() public {
        uint fee = schrute_Stanley.fee();
        assertEq(fee, 3);

    }

    function testSetFee() public {
        uint fee = schrute_Stanley.fee();
        assertEq(fee, 3);

        poolFactory.setFee(address(schrute_Stanley), 0);
        fee = schrute_Stanley.fee();
        assertEq(fee, 0);

        // the owner of the poolfactory is this contract,
        // so we should be able to set the fee from this contract

        schrute_Stanley.setFee(5);
        fee = schrute_Stanley.fee();
        assertEq(fee, 5);

    }

    function testNonOwnerSetFee() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(bytes('Ownable: caller is not the owner'));
        poolFactory.setFee(address(newTokenA_newTokenB), 0);

        // call setFee directly on pool contract
        vm.prank(address(0xBEEF));
        vm.expectRevert(bytes('Only factory or owner'));
        newTokenA_newTokenB.setFee(0);

    }

    function testSwapWithFees() public {
        // setting up two pools with the same reserves, one with fees turned off
        schrute_Stanley.initializePool(1000 ether, 100 ether);
        newTokenA_newTokenB.initializePool(1000 ether, 100 ether);
        poolFactory.setFee(address(newTokenA_newTokenB), 0);

        (, uint stanleyOut) = schrute_Stanley.getTokenAndAmountIn(address(schruteBucks), 50 ether);
        (, uint newTokenBOut) = newTokenA_newTokenB.getTokenAndAmountIn(address(newTokenA), 50 ether);

        console.log(stanleyOut * 1 ether/newTokenBOut);

        // so it works, but not sure how to test with assertEq or something

    }

    


}
