import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert, expect } from "chai";
import { ContractTransaction } from "ethers";
import { network, ethers } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import {
  NFTSwap,
  NFTSwap__factory,
  NFTMock,
  NFTMock__factory,
} from "../../typechain";

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("NFTSwap", () => {
      const zeroAddress = "0x0000000000000000000000000000000000000000";

      let nftMock: NFTMock;
      let nftSwap: NFTSwap;
      let accounts: SignerWithAddress[];
      let deployer: SignerWithAddress;
      let owner_1: SignerWithAddress;
      let owner_2: SignerWithAddress;

      beforeEach(async () => {
        accounts = await ethers.getSigners();
        deployer = accounts[0];
        owner_1 = accounts[1];
        owner_2 = accounts[2];

        const NFTMock: NFTMock__factory = await ethers.getContractFactory(
          "NFTMock"
        );
        nftMock = await NFTMock.deploy([
          deployer.address,
          owner_1.address,
          owner_2.address,
        ]);
        await nftMock.deployed();

        const NFTSwap: NFTSwap__factory = await ethers.getContractFactory(
          "NFTSwap",
          deployer
        );
        nftSwap = await NFTSwap.deploy();
        await nftSwap.deployed();
      });

      describe("getAllExchanges", () => {
        it("retreives all token id pairs", async () => {
          const allExchanges = await nftSwap.getAllExchanges();

          assert(allExchanges);
        });
      });

      describe("createExchange", () => {
        beforeEach(async () => {
          const tx: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            0
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await nftSwap.createExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          await tx1.wait(1);
        });

        it("reverts if function caller already owns the token to be received", async () => {
          await expect(
            nftSwap.createExchange(nftMock.address, nftMock.address, 0, 4)
          ).to.be.revertedWith("NFTSwap__AlreadyOwnedToken");
        });

        it("transfers the exchange token to the contract", async () => {
          const tokenOwnerAddress = await nftMock.ownerOf(0);

          expect(tokenOwnerAddress).to.equal(nftSwap.address);
        });

        it("records exchange data", async () => {
          const exchange = await nftSwap.getExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );

          expect(exchange.owner).to.equal(deployer.address);
        });

        it("reverts if exchange exists", async () => {
          await expect(
            nftSwap.createExchange(nftMock.address, nftMock.address, 0, 1)
          ).to.be.revertedWith("NFTSwap__ExchangeExists");
        });
      });

      describe("createExchangeFor", () => {
        it("reverts if trader is zero address", async () => {
          await expect(
            nftSwap.createExchangeFor(
              zeroAddress,
              nftMock.address,
              nftMock.address,
              0,
              1
            )
          ).to.be.revertedWith("NFTSwap__ZeroAddress");
        });

        it("sets the trader for the exchange", async () => {
          const tx: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            4
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await nftSwap.createExchangeFor(
            owner_2.address,
            nftMock.address,
            nftMock.address,
            4,
            2
          );
          await tx1.wait(1);

          const exchange = await nftSwap.getExchange(
            nftMock.address,
            nftMock.address,
            4,
            2
          );

          expect(exchange.trader).to.equal(owner_2.address);
        });
      });

      describe("trade", () => {
        beforeEach(async () => {
          const tx: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            0
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await nftSwap.createExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          await tx1.wait(1);

          const tx2: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            4
          );
          await tx2.wait(1);

          const tx3: ContractTransaction = await nftSwap.createExchangeFor(
            owner_2.address,
            nftMock.address,
            nftMock.address,
            4,
            2
          );
          await tx3.wait(1);
        });
        it("reverts if exchange does not exists", async () => {
          await expect(
            nftSwap.trade(nftMock.address, nftMock.address, 4, 1)
          ).to.be.revertedWith("NFTSwap__NonexistentExchange");
        });

        it("reverts if trader is the owner of the exchange", async () => {
          await expect(
            nftSwap.trade(nftMock.address, nftMock.address, 0, 1)
          ).to.be.revertedWith("NFTSwap__InvalidTrader");
        });

        it("reverts if exchange is for specific trader and function caller is not the trader", async () => {
          nftSwap = nftSwap.connect(owner_1);

          await expect(
            nftSwap.trade(nftMock.address, nftMock.address, 4, 2)
          ).to.be.revertedWith("NFTSwap__InvalidTokenReceiver");
        });

        const trade = async () => {
          nftSwap = nftSwap.connect(owner_2);
          nftMock = nftMock.connect(owner_2);

          const tx: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            2
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await nftSwap.trade(
            nftMock.address,
            nftMock.address,
            4,
            2
          );
          await tx1.wait(1);
        };

        it("swaps NFTs between exchange owner and trader", async () => {
          await trade();

          const owner0: string = await nftMock.ownerOf(4);
          const owner1: string = await nftMock.ownerOf(2);

          assert(owner0 === owner_2.address && owner1 === deployer.address);
        });

        it("deletes exchange", async () => {
          await trade();

          const exchange = await nftSwap.getExchange(
            nftMock.address,
            nftMock.address,
            4,
            2
          );

          expect(exchange.owner).to.equal(zeroAddress);
        });
      });

      describe("updateExchangeOwner", () => {
        beforeEach(async () => {
          const tx: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            0
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await nftSwap.createExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          await tx1.wait(1);
        });
        it("reverts if new owner is zero address", async () => {
          await expect(
            nftSwap.updateExchangeOwner(
              zeroAddress,
              nftMock.address,
              nftMock.address,
              2,
              4
            )
          ).to.be.revertedWith("NFTSwap__ZeroAddress");
        });

        it("reverts if function caller is not the exchange owner", async () => {
          nftSwap = nftSwap.connect(owner_1);

          await expect(
            nftSwap.updateExchangeOwner(
              owner_1.address,
              nftMock.address,
              nftMock.address,
              0,
              1
            )
          ).to.be.revertedWith("NFTSwap__NotOwner");
        });

        it("updates exchange owner", async () => {
          const tx: ContractTransaction = await nftSwap.updateExchangeOwner(
            owner_1.address,
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          await tx.wait(1);

          const exchange = await nftSwap.getExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          expect(exchange.owner).to.equal(owner_1.address);
        });
      });

      describe("updateExchangeTrader", () => {
        beforeEach(async () => {
          const tx: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            0
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await nftSwap.createExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          await tx1.wait(1);
        });

        it("reverts if function caller is not the exchange owner", async () => {
          nftSwap = nftSwap.connect(owner_1);

          await expect(
            nftSwap.updateExchangeTrader(
              owner_1.address,
              nftMock.address,
              nftMock.address,
              0,
              1
            )
          ).to.be.revertedWith("NFTSwap__NotOwner");
        });

        it("reverts if new trader is the exchange owner", async () => {
          await expect(
            nftSwap.updateExchangeTrader(
              deployer.address,
              nftMock.address,
              nftMock.address,
              0,
              1
            )
          ).to.be.revertedWith("NFTSwap__InvalidTrader");
        });

        it("updates trader", async () => {
          const tx2: ContractTransaction = await nftSwap.updateExchangeTrader(
            owner_2.address,
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          await tx2.wait(1);

          const exchange = await nftSwap.getExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          expect(exchange.trader).to.equal(owner_2.address);
        });
      });

      describe("cancelExchange", () => {
        beforeEach(async () => {
          const tx: ContractTransaction = await nftMock.approve(
            nftSwap.address,
            0
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await nftSwap.createExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );
          await tx1.wait(1);
        });

        it("reverts if function caller is not the exchange owner", async () => {
          nftSwap = nftSwap.connect(owner_1);
          await expect(
            nftSwap.cancelExchange(
              nftMock.address,
              nftMock.address,
              0,
              1,
              deployer.address
            )
          ).to.be.revertedWith("NFTSwap__NotOwner");
        });

        it("reverts if nft recipient is the zero address", async () => {
          await expect(
            nftSwap.cancelExchange(
              nftMock.address,
              nftMock.address,
              0,
              1,
              zeroAddress
            )
          ).to.be.revertedWith("NFTSwap__InvalidRecipient");
        });

        it("reverts if nft recipient is nft0", async () => {
          await expect(
            nftSwap.cancelExchange(
              nftMock.address,
              nftMock.address,
              0,
              1,
              nftMock.address
            )
          ).to.be.revertedWith("NFTSwap__InvalidRecipient");
        });

        it("reverts if nft recipient is nft1", async () => {
          await expect(
            nftSwap.cancelExchange(
              nftMock.address,
              nftMock.address,
              0,
              1,
              nftMock.address
            )
          ).to.be.revertedWith("NFTSwap__InvalidRecipient");
        });

        it("transfers nft to receiver", async () => {
          const tx: ContractTransaction = await nftSwap.cancelExchange(
            nftMock.address,
            nftMock.address,
            0,
            1,
            deployer.address
          );
          await tx.wait(1);

          const tokenId2Owner = await nftMock.ownerOf(0);

          expect(tokenId2Owner).to.equal(deployer.address);
        });

        it("deletes exchange", async () => {
          const tx: ContractTransaction = await nftSwap.cancelExchange(
            nftMock.address,
            nftMock.address,
            0,
            1,
            deployer.address
          );
          await tx.wait(1);

          const exchange = await nftSwap.getExchange(
            nftMock.address,
            nftMock.address,
            0,
            1
          );

          expect(exchange.owner).to.equal(zeroAddress);
        });
      });
    });
