# NFTSwap

### Swap your NFTs!

[NFTSwap](https://rinkeby.etherscan.io/address/0x528CE0aD8394018aa31FfEc6e9c63fDeC770905c) is a Decentralized Exchange for all your NFTs on the Ethereum network. Swap your NFTs with any trader or a specific trader depending on how the exchange is created.

### How it works

NFT owners may create exchanges specifying which NFT they would like to trade and the NFT they would like to trade it for. They may also specify the trader they would like to trade with. Traders with the requested NFT may trade and a swap will be made.

# Local Development

#### Install dependencies:

```shell
yarn
```

#### Run test scripts

```shell
yarn test
```

#### Deploy to several networks

`Note: Signer, RPC URL and ETHERSCAN API KEY must be provided as environment variables`

```shell
yarn hardhat deploy --network rinkeby

yarn hardhat deploy --network mainnet
```
