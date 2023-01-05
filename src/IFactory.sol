pragma solidity 0.8.7;

interface IFactory {

    function getPool(address token1, address token2) external view returns(address pool); 
    function owner() external returns(address);
}