pragma solidity 0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./NSPool.sol";
import "./NSPoolStandard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// import "./NSPool_constructor.sol";



contract PoolFactory is Ownable {


    mapping(address => mapping(address => address)) internal tokenToTokenToPool;


    uint salt;
    event PoolCreated();

    address poolImplementation;

    modifier Createable(address tokenA, address tokenB) {
        require(tokenA != tokenB);
        require(tokenToTokenToPool[tokenA][tokenB] == address(0));
        _;
    }



    constructor() {

        poolImplementation = address(new NSPool());

    }


    function getPool(address token1, address token2) public view returns(address pool) {
        pool = tokenToTokenToPool[token1][token2];
    }
    function setFee(address pool, uint newFee) public onlyOwner {
        NSPool(pool).setFee(newFee);
    }

    function _createPair(address tokenA, address tokenB, address pool) private returns (address) {
        tokenToTokenToPool[tokenA][tokenB] = pool;
        tokenToTokenToPool[tokenB][tokenA] = pool;
        emit PoolCreated();
        return pool;
    }

    function createPairClone(address tokenA, address tokenB) public Createable(tokenA, tokenB) returns (address) {
        
        address pool = Clones.clone(poolImplementation);
        NSPool(pool).__init__(tokenA, tokenB);
        return _createPair(tokenA, tokenB, pool);

    }

    function createPairCreate2(address tokenA, address tokenB) public Createable(tokenA, tokenB) returns(address) {
        bytes memory bytecode = type(NSPool).creationCode;
        salt ++;
        address pool = Create2.deploy(0,bytes32(salt), bytecode);
        NSPool(pool).__init__(tokenA, tokenB);
        return _createPair(tokenA, tokenB, pool);


    }

    function createPairStandard(address tokenA, address tokenB) public Createable(tokenA, tokenB) returns(address) {
        address pool = address(new NSPoolStandard(tokenA, tokenB));
        return _createPair(tokenA, tokenB, pool);
        


    }
    







}