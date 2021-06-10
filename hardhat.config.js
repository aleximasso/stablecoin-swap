require('dotenv').config();
require('solidity-coverage');
require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-etherscan');
const { removeConsoleLog } = require('hardhat-preprocessor');

module.exports = {
  solidity: {
    compilers: [{
      version: '0.8.0',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }, {
      version: '0.6.6',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }]
  },
  preprocess: {
    eachLine: removeConsoleLog((hre) => hre.network.name !== 'hardhat' && hre.network.name !== 'localhost')
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
      accounts: {
        mnemonic: process.env.SEED
      }
    },
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
      accounts: {
        mnemonic: process.env.TEST_SEED
      }
    }
  },
  etherscan: {
    apiKey: process.env.EXPLORER_KEY
  },
  mocha: {
    timeout: 180000
  }
};