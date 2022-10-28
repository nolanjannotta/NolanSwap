// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "forge-std/Script.sol";
import "../src/PoolFactory.sol";
import "../src/MockERC20.sol";
import "forge-std/console.sol";


contract Deploy is Script {
    function run() external returns(address _factory, address _schrute, address _stanley) {
        // uint256 deployerPrivateKey = vm.env(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        PoolFactory poolFactory = new PoolFactory();
        MockERC20 schrute = new MockERC20("SchruteBucks", "SCHRUTE");
        MockERC20 stanley = new MockERC20("StanleyNickels", "STANLEY");
        _factory = address(poolFactory);
        _schrute = address(schrute);
        _stanley = address(stanley);
        vm.stopBroadcast();
    }
}