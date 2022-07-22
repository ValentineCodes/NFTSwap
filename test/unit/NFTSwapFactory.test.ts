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
      let owner_0: SignerWithAddress;
      let owner_1: SignerWithAddress;
      let owner_2: SignerWithAddress;

      /* Deploy contract */
      beforeEach(async () => {
        accounts = await ethers.getSigners();
        owner_0 = accounts[0];
        owner_1 = accounts[1];
        owner_2 = accounts[2];

        factory = await ethers.getContract("NFTSwapFactory");
      });

      /* Tests */
      describe("contructor", () => {});
    });

module.exports.tags = ["all", "factory"];
