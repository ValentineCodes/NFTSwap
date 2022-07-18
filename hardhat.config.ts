import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-deploy";
import "hardhat-contract-sizer";

import "./tasks";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const MAINNET_RPC_URL =
  process.env.MAINNET_RPC_URL ||
  process.env.ALCHEMY_MAINNET_RPC_URL ||
  "https://eth-mainnet.alchemyapi.io/v2/your-api-key";

const RINKEBY_RPC_URL =
  process.env.RINKEBY_RPC_URL ||
  "https://eth-rinkeby.alchemyapi.io/v2/your-api-key";

const KOVAN_RPC_URL =
  process.env.KOVAN_RPC_URL ||
  "https://eth-kovan.alchemyapi.io/v2/your-api-key";

const POLYGON_MAINNET_RPC_URL =
  process.env.POLYGON_MAINNET_RPC_URL ||
  "https://polygon-mainnet.alchemyapi.io/v2/your-api-key";

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x";
// optional
const MNEMONIC = process.env.MNEMONIC || "your mnemonic";

// Your API key for Etherscan, obtain one at https://etherscan.io/
const ETHERSCAN_API_KEY =
  process.env.ETHERSCAN_API_KEY || "Your etherscan API key";

const POLYGONSCAN_API_KEY =
  process.env.POLYGONSCAN_API_KEY || "Your polygonscan API key";

const REPORT_GAS = process.env.REPORT_GAS || false;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // // If you want to do some forking, uncomment this
      // forking: {
      //   url: MAINNET_RPC_URL
      // }
      chainId: 31337,
    },
    localhost: {
      chainId: 31337,
    },
    kovan: {
      url: KOVAN_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //accounts: {
      //     mnemonic: MNEMONIC,
      // },
      saveDeployments: true,
      chainId: 42,
    },
    rinkeby: {
      url: RINKEBY_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      saveDeployments: true,
      chainId: 4,
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      //   accounts: {
      //     mnemonic: MNEMONIC,
      //   },
      saveDeployments: true,
      chainId: 1,
    },
    polygon: {
      url: POLYGON_MAINNET_RPC_URL,
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      saveDeployments: true,
      chainId: 137,
    },
  },
  etherscan: {
    // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
    apiKey: {
      rinkeby: ETHERSCAN_API_KEY,
      kovan: ETHERSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
    },
  },
  solidity: {
    compilers: [{ version: "0.8.7" }, { version: "0.5.16" }],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    outputFile: "gas-report.txt",
    currency: "USD",
  },
  contractSizer: {
    runOnCompile: false,
    only: ["AfterLife"],
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    feeCollector: {
      default: 1,
    },
  },
  mocha: {
    timeout: 200000, // 200 seconds max for running tests
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
};

export default config;
