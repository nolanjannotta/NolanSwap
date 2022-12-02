pragma solidity 0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./NSPool.sol";
// import "./NSPool_constructor.sol";



contract PoolFactory is Ownable {


    mapping(address => mapping(address => address)) internal tokenToTokenToPool;


    uint salt;


    function getPool(address token1, address token2) public view returns(address pool) {
        pool = tokenToTokenToPool[token1][token2];
    }

    function createPair(address tokenA, address tokenB) public returns(address) {
        require(tokenA != tokenB);
        require(tokenToTokenToPool[tokenA][tokenB] == address(0));
        bytes memory bytecode = type(NSPool).creationCode;
        salt ++;
        address pool = Create2.deploy(0,bytes32(salt), bytecode);
        NSPool(pool).initialize(tokenA, tokenB);
        tokenToTokenToPool[tokenA][tokenB] = pool;
        tokenToTokenToPool[tokenB][tokenA] = pool;
        return pool;

    }
    
    function setFee(address pool, uint newFee) public onlyOwner {
        NSPool(pool).setFee(newFee);
    }

    // TODO: create function to deploy pools normally without create2





}