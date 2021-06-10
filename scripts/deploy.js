
const hre = require('hardhat');
const ethers = hre.ethers;

// ------------------------
// DEPLOYMENT VARIABLES
// ------------------------

const feeReceiverAddress =  '0xaaaa5305081447839316859e8104033faD62C05b';   // Address who should receive fee from exchanges
const initialFeeAmount =    '500';                                          // 5% from all exchanges
const uniswapFactory =      '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';   // Same address for all networks
const wethAddress =         '0xc778417E063141139Fce010982780140Aa0cD5Ab';   // Rinkeby WETH address
const daiAddress =          '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';   // Rinkeby DAI address

async function main() {
    if (!feeReceiverAddress) {
        throw 'Fee receiver values are missing. Please fill and re-run the script!'
    }

    const Exchange = await ethers.getContractFactory('Exchange');
    const UniswapOracle = await ethers.getContractFactory('UniswapOracle');
    const MockStablecoin = await ethers.getContractFactory('MockStablecoin');


    pusdContract = await MockStablecoin.deploy('pUSD Stablecoin', 'PUSD');
    await pusdContract.deployed();
    console.log('1) PUSD contract address:', pusdContract.address);

    priviContract = await MockStablecoin.deploy('PRIVI Token', 'PRIVI');
    await priviContract.deployed();
    console.log('2) PRIVI contract address:', priviContract.address);

    uniswapOracle = await UniswapOracle.deploy(uniswapFactory, daiAddress, wethAddress);
    await uniswapOracle.deployed();
    console.log('3) Uniswap oracle contract:', uniswapOracle.address);

    exchange = await Exchange.deploy(pusdContract.address, priviContract.address, feeReceiverAddress, initialFeeAmount, uniswapOracle.address);
    await exchange.deployed();
    console.log('4) Exchange contract:', exchange.address);

    minterRoleHash = await pusdContract.MINTER_ROLE();
    await pusdContract.grantRole(minterRoleHash, exchange.address);
    await priviContract.grantRole(minterRoleHash, exchange.address);
    console.log("5) Contract granted as a minter!");
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});
