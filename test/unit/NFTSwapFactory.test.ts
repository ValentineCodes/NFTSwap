import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";
import { network, ethers } from "hardhat";
import { developmentChains, networkConfig } from "../../helper-hardhat-config";
import { NFTSwapFactory, NFTSwapFactory__factory } from "../../typechain";

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("NFTSwapFactory", () => {
      let factory: NFTSwapFactory;
      let accounts: SignerWithAddress[];
      let deployer: SignerWithAddress;
      let account_1: SignerWithAddress;
      let account_2: SignerWithAddress;

      /* Deploy contract */
      beforeEach(async () => {
        accounts = await ethers.getSigners();
        deployer = accounts[0];
        account_1 = accounts[1];
        account_2 = accounts[2];

        const NFTSwapFactory: NFTSwapFactory__factory =
          await ethers.getContractFactory("NFTSwapFactory");

        /* Deploy contract to the network */
        factory = await NFTSwapFactory.deploy();

        /* Wait for deployment to be completed */
        await factory.deployed();
      });

      /* Tests */
      describe("contructor", () => {});
    });

module.exports.tags = ["all", "factory"];
