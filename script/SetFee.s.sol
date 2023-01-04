// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "forge-std/Script.sol";
import "../src/PoolFactory.sol";
import "../src/MockERC20.sol";
import "forge-std/console.sol";


contract SetFee is Script {
    function run() external returns(address _factory, address _schrute, address _stanley, address _ct1, address _ct2) {
        // uint256 deployerPrivateKey = vm.env(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        PoolFactory factory = PoolFactory(0x986aaa537b8cc170761FDAC6aC4fc7F9d8a20A8C);
        factory.setFee(0x0f40af77deDff4d00c1CDe8D1FEeA9C3D7D1076f, 3);
        vm.stopBroadcast();
    }
}