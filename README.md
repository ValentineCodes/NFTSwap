# NFTSwap

### Swap your NFTs!

NFTSwap is a Decentralized Exchange for all your NFTs on the Ethereum network. NFT owners may create exchanges specifying which NFT they would like to trade and the NFT they would like to trade it for. Traders with the requested NFT may trade and a swap will be made.

This consists of two main contracts:

1. [NFTSwapFactory](https://rinkeby.etherscan.io/address/0x9Fbd6139b0B2EEF1a1EC7561Fd90c914CD5da842): This creates swap pools and manages fees.
2. NFTSwapPool: This creates exchanges and handles trades

# Local Development

#### Install dependencies:

```shell
yarn
```

#### Run test scripts

```3shell
yarn hardhat test
```

#### Run local node:

```shell
yarn hardhat node
```

#### Deploy to several networks

`Note: Signer, RPC URL and ETHERSCAN API KEY must be provided as environment variables`

```shell
yarn hardhat deploy --network localhost

yarn hardhat deploy --network rinkeby

yarn hardhat deploy --network mainnet
```
