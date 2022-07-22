import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";
import { network, ethers } from "hardhat";
import { developmentChains, networkConfig } from "../../helper-hardhat-config";
import { NFTSwapFactory, NFTSwapFactory__factory } from "../../typechain";

developmentChains.includes(network.name)
  ? describe.skip
  : describe("NFTSwapFactory", () => {
      let factoryContract: NFTSwapFactory;
      let factory: NFTSwapFactory;
      let accounts: SignerWithAddress[];
      let deployer: SignerWithAddress;
      let owner_1: SignerWithAddress;
      let owner_2: SignerWithAddress;

      /* Deploy contract */
      beforeEach(async () => {
        accounts = await ethers.getSigners();
        deployer = accounts[0];
        owner_1 = accounts[1];
        owner_2 = accounts[2];

        factoryContract = await ethers.getContract("NFTSwapFactory");
        factory = await factoryContract.connect(deployer);
      });

      /* Tests */
      describe("contructor", () => {
        it("initializes the feeReceiver and feeReceiverSetter to the contract deployer", async () => {
          const feeReceiver = await factory.getFeeReceiver();
          const feeReceiverSetter = await factory.getFeeReceiverSetter();

          expect(feeReceiver).to.equal(deployer.address);
          expect(feeReceiverSetter).to.equal(deployer.address);
        });
      });
    });

module.exports.tags = ["all", "factory"];
