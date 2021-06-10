const { expect } = require('chai');
const { parse } = require('dotenv');
const parseEther = ethers.utils.parseEther;

describe('End-to-end test', function () {
  // Contracts
  let exchange, uniswapOracle, pusd, privi;

  // Addresses
  let owner, feeReceiver, user1, user2;

  before(async function () {
    const Exchange = await ethers.getContractFactory('Exchange');
    const UniswapOracle = await ethers.getContractFactory('MockOracle');
    const MockStablecoin = await ethers.getContractFactory('MockStablecoin');

    [owner, feeReceiver, user1, user2] = await ethers.getSigners();

    pusd = await MockStablecoin.deploy('pUSD Stablecoin', 'PUSD');
    await pusd.deployed();

    privi = await MockStablecoin.deploy('PRIVI Token', 'PRIVI');
    await privi.deployed();

    uniswapOracle = await UniswapOracle.deploy();
    await uniswapOracle.deployed();

    exchange = await Exchange.deploy(pusd.address, privi.address, pusd.address, privi.address, feeReceiver.address, '500', uniswapOracle.address);
    await exchange.deployed();

    minterRoleHash = await pusd.MINTER_ROLE();
    await pusd.grantRole(minterRoleHash, exchange.address);
    await privi.grantRole(minterRoleHash, exchange.address);
  })

  describe('Swap PRIVI to PUSD', async function () {
    it('Owner mints tokens for swap', async function () {
      await privi.mint(user1.address, parseEther('100'))

      const priviBalance = await privi.balanceOf(user1.address)
      expect(priviBalance).to.be.eq(parseEther('100'))

      const totalSupply = await privi.totalSupply()
      expect(totalSupply).to.be.eq(parseEther('100'))
    })

    it('Approve and swap tokens', async function () {
      await privi.connect(user1).approve(exchange.address, parseEther('100'))
      await exchange.connect(user1).priviToPusd(parseEther('100'))
    })

    it('Check balances after swap', async function () {
      const pusdBalance = await pusd.balanceOf(user1.address)
      expect(pusdBalance).to.be.eq((2000 * 10**6).toString())

      const totalSupply = await pusd.totalSupply()
      expect(totalSupply).to.be.eq((2000 * 10**6).toString())

      const feeReceiverBalance = await privi.balanceOf(feeReceiver.address)
      expect(feeReceiverBalance).to.be.eq(parseEther('5'))
    })
  })
});
