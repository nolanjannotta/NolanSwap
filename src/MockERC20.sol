// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockERC20 is ERC20 {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

        _mint(msg.sender, 2000 ether);
    }

    function mint(uint amount) public {
        _mint(msg.sender, amount);
    }

}
