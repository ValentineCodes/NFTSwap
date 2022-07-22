import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert, expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";
import { network, ethers } from "hardhat";
import { developmentChains, networkConfig } from "../../helper-hardhat-config";
import { NFTSwapFactory } from "../../typechain";

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("NFTSwapFactory", () => {
      const nftAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
      const zeroAddress = "0x0000000000000000000000000000000000000000";
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

      describe("setFeeReceiver", () => {
        it("reverts if function caller is not the fee receiver setter", async () => {
          factory = await factoryContract.connect(owner_1.address);

          await expect(
            factory.setFeeReceiver(owner_1.address)
          ).to.be.revertedWith("NFTSwapFactory__NotFeeSetter");
        });

        it("updates fee receiver", async () => {
          const tx: ContractTransaction = await factory.setFeeReceiver(
            owner_1.address
          );

          await tx.wait(1);

          const feeReceiver = await factory.getFeeReceiver();

          expect(feeReceiver).to.equal(owner_1.address);
        });
      });

      describe("setFeeReceiverSetter", () => {
        it("reverts if function caller is not the fee receiver setter", async () => {
          factory = await factoryContract.connect(owner_1.address);

          await expect(
            factory.setFeeReceiverSetter(owner_1.address)
          ).to.be.revertedWith("NFTSwapFactory__NotFeeSetter");
        });

        it("updates fee receiver setter", async () => {
          const tx: ContractTransaction = await factory.setFeeReceiverSetter(
            owner_1.address
          );

          await tx.wait(1);

          const feeReceiver = await factory.getFeeReceiverSetter();

          expect(feeReceiver).to.equal(owner_1.address);
        });
      });

      describe("getFeeReceiver", () => {
        it("gets fee receiver", async () => {
          const feeReceiver = await factory.getFeeReceiver();
          expect(feeReceiver).to.equal(owner_1.address);
        });
      });

      describe("getFeeReceiverSetter", () => {
        it("gets fee receiver setter", async () => {
          const feeReceiverSetter = await factory.getFeeReceiverSetter();
          expect(feeReceiverSetter).to.equal(owner_1.address);
        });
      });

      let pool;
      describe("createPool", () => {
        it("creates pool", async () => {
          const tx: ContractTransaction = await factory.createPool(
            nftAddress,
            nftAddress
          );

          await tx.wait(1);

          pool = await factory.getPool(nftAddress, nftAddress);

          assert(pool !== zeroAddress);
        });

        it("reverts if nft address is zero address", async () => {
          await expect(
            factory.createPool(nftAddress, zeroAddress)
          ).to.be.revertedWith("NFTSwapFactory__ZeroAddress");
        });

        it("reverts if pool already exists", async () => {
          await expect(
            factory.createPool(nftAddress, nftAddress)
          ).to.be.revertedWith("NFTSwapFactory__PoolAlreadyExists");
        });

        it("pushes pool to array of pools", async () => {
          const allPools = await factory.getAllPools();

          expect(allPools[0]).to.equal(pool);
        });
      });

      describe("gets pool", () => {
        it("gets pool", async () => {
          const _pool = await factory.getPool(nftAddress, nftAddress);

          expect(_pool).to.equal(pool);
        });
      });

      describe("gets all pools", () => {
        it("gets all pools", async () => {
          const allPools = await factory.getAllPools();

          assert(allPools);
        });
      });
    });

module.exports.tags = ["all", "factory"];
