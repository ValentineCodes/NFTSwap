import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert, expect } from "chai";
import { ContractTransaction } from "ethers";
import { network, ethers } from "hardhat";
import { developmentChains } from "../../helper-hardhat-config";
import { NFTMockABI, NFTSwapPoolABI } from "../../constants";

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("NFTSwapPool", () => {
      const poolAddress: string = "0xa608a7894fd629B7EfF2cc21Ecc40652Dc21389A";
      const nftMockAddress: string =
        "0x5FbDB2315678afecb367f032d93F642f64180aa3";
      const zeroAddress = "0x0000000000000000000000000000000000000000";
      let pool;
      let nftMock;
      let accounts: SignerWithAddress[];
      let deployer: SignerWithAddress;
      let owner_1: SignerWithAddress;
      let owner_2: SignerWithAddress;

      beforeEach(async () => {
        accounts = await ethers.getSigners();
        deployer = accounts[0];
        owner_1 = accounts[1];
        owner_2 = accounts[2];

        pool = new ethers.Contract(poolAddress, NFTSwapPoolABI, deployer);
        // nftMock = new ethers.Contract(nftMockAddress, NFTMockABI, deployer);
        nftMock = await ethers.getContract("NFTMock");
      });

      describe("getNFTPair", () => {
        it("retreives nft pair", async () => {
          const pair = await pool.getNFTPair();

          assert(pair);
        });
      });

      describe("getAllPairs", () => {
        it("retreives all token id pairs", async () => {
          const allPairs = await pool.getAllPairs();

          assert(allPairs);
        });
      });

      describe("createExchange", () => {
        it("reverts if function caller already owns the token to be received", async () => {
          await expect(pool.createExchange(0, 4)).to.be.revertedWith(
            "NFTSwapPool__AlreadyOwnedToken"
          );
        });

        it("transfers the exchange token to the pool contract", async () => {
          const tx: ContractTransaction = await nftMock.approve(poolAddress, 0);
          await tx.wait(1);

          const tx1: ContractTransaction = await pool.createExchange(0, 1);
          await tx1.wait(1);

          const tokenOwnerAddress = await nftMock.ownerOf(0);

          expect(tokenOwnerAddress).to.equal(poolAddress);
        });

        it("records exchange data", async () => {
          const exchange = await pool.getExchange(0, 1);

          expect(exchange.owner).to.equal(deployer.address);
        });

        it("reverts if exchange exists", async () => {
          await expect(pool.createExchange(0, 1)).to.be.revertedWith(
            "NFTSwapPool__ExchangeExists"
          );
        });
      });

      describe("createExchangeFor", () => {
        it("reverts if trader is zero address", async () => {
          await expect(
            pool.createExchangeFor(zeroAddress, 0, 1)
          ).to.be.revertedWith("NFTSwapPool__ZeroAddress");
        });

        it("sets the trader for the exchange", async () => {
          const tx: ContractTransaction = await nftMock.approve(poolAddress, 4);
          await tx.wait(1);

          const tx1: ContractTransaction = await pool.createExchangeFor(
            owner_2.address,
            4,
            2
          );
          await tx1.wait(1);

          const exchange = await pool.getExchange(4, 2);

          expect(exchange.trader).to.equal(owner_2.address);
        });
      });

      describe("trade", () => {
        it("reverts if exchange does not exists", async () => {
          await expect(pool.trade(4, 1)).to.be.revertedWith(
            "NFTSwapPool__NonexistentExchange"
          );
        });

        it("reverts if trader is the owner of the exchange", async () => {
          await expect(pool.trade(0, 1)).to.be.revertedWith(
            "NFTSwapPool__InvalidTrader"
          );
        });

        it("reverts if exchange is for specific trader and function caller is not the trader", async () => {
          const _pool = await pool.connect(owner_1.address);
          await expect(_pool.trade(4, 2)).to.be.revertedWith(
            "NFTSwapPool__InvalidTokenReceiver"
          );
        });

        it("transfers exchange token to trader", async () => {
          const _pool = new ethers.Contract(
            poolAddress,
            NFTSwapPoolABI,
            owner_2
          );
          const _nftMock = new ethers.Contract(
            nftMockAddress,
            NFTMockABI,
            owner_2
          );

          const tx: ContractTransaction = await _nftMock.approve(
            poolAddress,
            2
          );
          await tx.wait(1);

          const tx1: ContractTransaction = await _pool.trade(4, 2);
          await tx1.wait(1);

          const owner: string = await _nftMock.ownerOf(4);

          expect(owner).to.equal(owner_2.address);
        });

        it("transfers trader token to exchange owner", async () => {
          const owner: string = await nftMock.ownerOf(2);

          expect(owner).to.equal(deployer.address);
        });

        it("deletes exchange", async () => {
          const exchange = await pool.getExchange(4, 2);

          expect(exchange.owner).to.equal(zeroAddress);
        });
      });

      describe("updateExchangeOwner", () => {
        it("reverts if new owner is zero address", async () => {
          await expect(
            pool.updateExchangeOwner(zeroAddress, 2, 4)
          ).to.be.revertedWith("NFTSwapPool__ZeroAddress");
        });

        it("reverts if function caller is not the exchange owner", async () => {
          const _pool = await pool.connect(owner_1.address);

          await expect(
            _pool.updateExchangeOwner(owner_1.address, 0, 1)
          ).to.be.revertedWith("NFTSwapPool__NotOwner");
        });

        it("updates exchange owner", async () => {
          const tx: ContractTransaction = await pool.updateExchangeOwner(
            owner_1.address,
            0,
            1
          );
          await tx.wait(1);

          const exchange = await pool.getExchange(0, 1);
          expect(exchange.owner).to.equal(owner_1.address);
        });
      });

      describe("updateExchangeTrader", () => {
        it("reverts if function caller is not the exchange owner", async () => {
          await expect(
            pool.updateExchangeTrader(owner_1.address, 0, 1)
          ).to.be.revertedWith("NFTSwapPool__NotOwner");
        });

        it("reverts if new trader is the exchange owner", async () => {
          const _pool = await pool.connect(owner_1.address);
          await expect(
            _pool.updateExchangeTrader(owner_1.address, 0, 1)
          ).to.be.revertedWith("NFTSwapPool__InvalidTrader");
        });

        it("updates trader", async () => {
          const tx: ContractTransaction = await nftMock.approve(poolAddress, 2);
          await tx.wait(1);

          const tx1: ContractTransaction = await pool.createExchange(2, 1);
          await tx1.wait(1);

          const tx2: ContractTransaction = await pool.updateExchangeTrader(
            owner_2.address,
            2,
            1
          );
          await tx2.wait(1);

          const exchange = await pool.getExchange(2, 1);
          expect(exchange.trader).to.equal(owner_2.address);
        });
      });

      describe("cancelExchange", () => {
        // reverts if function caller is not exchange owner
        // reverts if nft receiver is the zero address, or any of the nfts
        // transfers nft to receiver
        // deletes exchange

        it("reverts if function caller is not the exchange owner", async () => {
          const _pool = await pool.connect(owner_1.address);
          await expect(
            _pool.cancelExchange(2, 1, deployer.address)
          ).to.be.revertedWith("NFTSwapPool__NotOwner");
        });

        it("reverts if nft receiver is the zero address", async () => {
          await expect(
            pool.cancelExchange(2, 1, zeroAddress)
          ).to.be.revertedWith("NFTSwapPool__InvalidTo");
        });

        let nftPair;

        it("reverts if nft receiver is nft1 in pool", async () => {
          nftPair = await pool.getNFTPair();

          await expect(
            pool.cancelExchange(2, 1, nftPair[0])
          ).to.be.revertedWith("NFTSwapPool__InvalidTo");
        });

        it("reverts if nft receiver is nft2 in pool", async () => {
          await expect(
            pool.cancelExchange(2, 1, nftPair[1])
          ).to.be.revertedWith("NFTSwapPool__InvalidTo");
        });

        it("transfers nft to receiver", async () => {
          const tx: ContractTransaction = await pool.cancelExchange(
            2,
            1,
            deployer.address
          );
          await tx.wait(1);

          const tokenId2Owner = await nftMock.ownerOf(2);

          expect(tokenId2Owner).to.equal(deployer.address);
        });

        it("deletes exchange", async () => {
          const exchange = await pool.getExchange(2, 1);

          expect(exchange.owner).to.equal(zeroAddress);
        });
      });
    });
