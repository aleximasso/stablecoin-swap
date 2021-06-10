# Stablecoin exchange contract

Clone this repository: <br>
`https://github.com/Araton95/stablecoin-swap.git`

Install dependencies: <br>
`cd stablecoin-swap && npm install`

### Tests

The project uses [HardHat](https://hardhat.org/), so all additional methods and plugins can bee found on their [documentation](https://hardhat.org/getting-started/).  <br><br>
For UNIT tests run: <br>
`npx hardhat test`


### Deploy
Before running deployment you need to write out setup variables. Run `cp .env.example .env` and write down all params of `.env` file. Then go to `./scripts/deploy.js` and write down your own **feeReceiverAddress** address.<br><br> Rinkeby and Mainnet are supported, for deploy run: <br>
`npx hardhat run scripts/deploy.js --network [NETWORK]` (`rinkeby` or `mainnet`)
