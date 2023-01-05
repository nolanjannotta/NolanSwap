interface IFactory {

    function getPool(address token1, address token2) external view returns(address pool); 
    function owner() external returns(address);
}