import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";
import { network, ethers } from "hardhat";
import { developmentChains, networkConfig } from "../../helper-hardhat-config";
import { AfterLife, AfterLife__factory } from "../../typechain";

developmentChains.includes(network.name)
  ? describe.skip
  : describe("AfterLife", () => {
      let afterLife: AfterLife;
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

        afterLife = await ethers.getContract("AfterLife", deployer.address);
      });

      /* Tests */
      describe("contructor", () => {
        it("initializes with the correct name", async () => {
          const name: string = await afterLife.name();

          expect(name).to.equal("AfterLife");
        });
        it("initializes with the correct symbol", async () => {
          const symbol: string = await afterLife.symbol();

          expect(symbol).to.equal("AL");
        });
        it("initializes with the correct total supply", async () => {
          const totalSupply: BigNumber = await afterLife.totalSupply();

          expect(totalSupply).to.equal(
            ethers.utils.parseEther("1000000000000000.0")
          );
        });
        it("checks that total supply minted to deployer address", async () => {
          const balance: BigNumber = await afterLife.balanceOf(
            deployer.address
          );
          const totalSupply: BigNumber = await afterLife.totalSupply();

          expect(balance).to.equal(totalSupply);
        });
      });

      describe("balanceOf", () => {
        it("gets balance of account", async () => {
          const balance: BigNumber = await afterLife.balanceOf(
            deployer.address
          );
          const totalSupply: BigNumber = await afterLife.totalSupply();

          expect(balance).to.equal(totalSupply);
        });
      });

      describe("transfer", () => {
        const amount: BigNumber = ethers.utils.parseEther("1000.0");

        let prevSenderBalance: BigNumber, prevReceiverBalance: BigNumber;

        beforeEach(async () => {
          prevSenderBalance = await afterLife.balanceOf(deployer.address);
          prevReceiverBalance = await afterLife.balanceOf(account_1.address);

          const tx: ContractTransaction = await afterLife.transfer(
            account_1.address,
            amount
          );
          await tx.wait(1);
        });

        it("removes funds from sender's account", async () => {
          const currentBalance: BigNumber = await afterLife.balanceOf(
            deployer.address
          );

          expect(prevSenderBalance.sub(amount)).to.equal(currentBalance);
        });
        it("adds funds to receiver's account", async () => {
          const currentBalance: BigNumber = await afterLife.balanceOf(
            account_1.address
          );

          expect(currentBalance.sub(prevReceiverBalance)).to.equal(amount);
        });
        it("reverts if funds are insufficient", async () => {
          const balance = await afterLife.balanceOf(deployer.address);
          const amount: BigNumber = balance.add(ethers.utils.parseEther("1"));

          await expect(
            afterLife.transfer(account_1.address, amount)
          ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
        });
        it("emits event on transfer", async () => {
          await expect(afterLife.transfer(account_1.address, amount)).to.emit(
            afterLife,
            "Transfer"
          );
        });
      });

      describe("approve", () => {
        const amount: BigNumber = ethers.utils.parseEther("1000.0");
        it("allows spender to spend tokens from owner", async () => {
          const tx: ContractTransaction = await afterLife.approve(
            account_1.address,
            amount
          );
          await tx.wait(1);

          const allowance = await afterLife.allowance(
            deployer.address,
            account_1.address
          );

          expect(allowance).to.equal(amount);
        });

        it("emits event on approval", async () => {
          await expect(afterLife.approve(account_1.address, amount)).to.emit(
            afterLife,
            "Approval"
          );
        });
      });

      describe("transferFrom", () => {
        const amount: BigNumber = ethers.utils.parseEther("500.0");
        let prevSpenderAllowance: BigNumber,
          prevSenderBalance: BigNumber,
          prevReceiverBalance: BigNumber;

        beforeEach(async () => {
          /* Approve 1000 AL from owner */
          const tx1: ContractTransaction = await afterLife.approve(
            account_1.address,
            ethers.utils.parseEther("1000.0")
          );
          await tx1.wait(1);

          afterLife = afterLife.connect(account_1); // Connect spender account to contract

          /* Store current balances */
          prevSpenderAllowance = await afterLife.allowance(
            deployer.address,
            account_1.address
          );
          prevSenderBalance = await afterLife.balanceOf(deployer.address);
          prevReceiverBalance = await afterLife.balanceOf(account_2.address);

          /* Transfer 500 AL from owner */
          const tx2: ContractTransaction = await afterLife.transferFrom(
            deployer.address,
            account_2.address,
            amount
          );

          await tx2.wait(1);
        });

        it("reverts if allowance is insufficient", async () => {
          await expect(
            afterLife.transferFrom(
              deployer.address,
              account_2.address,
              ethers.utils.parseEther("1000.1")
            )
          ).to.be.revertedWith("ERC20: insufficient allowance");
        });

        it("removes amount from spender's allowance", async () => {
          const currentSpenderAllowance = await afterLife.allowance(
            deployer.address,
            account_1.address
          );

          expect(currentSpenderAllowance).to.equal(
            prevSpenderAllowance.sub(amount)
          );
        });

        it("removes funds from sender's account", async () => {
          const currentSenderBalance: BigNumber = await afterLife.balanceOf(
            deployer.address
          );

          expect(currentSenderBalance).to.equal(prevSenderBalance.sub(amount));
        });

        it("adds funds to receiver's account", async () => {
          const currentReceiverBalance: BigNumber = await afterLife.balanceOf(
            account_2.address
          );

          expect(currentReceiverBalance).to.equal(
            prevReceiverBalance.add(amount)
          );
        });

        it("emits event on transfer", async () => {
          await expect(
            afterLife.transferFrom(deployer.address, account_2.address, amount)
          ).to.emit(afterLife, "Transfer");
        });
      });

      describe("increaseAllowance", () => {
        const amount: BigNumber = ethers.utils.parseEther("500.0");

        beforeEach(async () => {
          /* Approve 1000 AL from owner */
          const tx: ContractTransaction = await afterLife.approve(
            account_1.address,
            ethers.utils.parseEther("1000.0")
          );
          await tx.wait(1);
        });

        it("increases allowance of spender", async () => {
          const prevAllowance: BigNumber = await afterLife.allowance(
            deployer.address,
            account_1.address
          );

          const tx: ContractTransaction = await afterLife.increaseAllowance(
            account_1.address,
            amount
          );
          await tx.wait(1);

          const currentAllowance: BigNumber = await afterLife.allowance(
            deployer.address,
            account_1.address
          );

          expect(currentAllowance).to.equal(prevAllowance.add(amount));
        });

        it("emits event on increase", async () => {
          await expect(
            afterLife.increaseAllowance(account_1.address, amount)
          ).to.emit(afterLife, "Approval");
        });
      });

      describe("decreaseAllowance", () => {
        const amount: BigNumber = ethers.utils.parseEther("500.0");

        beforeEach(async () => {
          /* Approve 1000 AL from owner */
          const tx: ContractTransaction = await afterLife.approve(
            account_1.address,
            ethers.utils.parseEther("1000.0")
          );
          await tx.wait(1);
        });

        it("reverts if subtracted value is greater than the current allowance", async () => {
          await expect(
            afterLife.decreaseAllowance(
              account_1.address,
              ethers.utils.parseEther("1000.1")
            )
          ).to.be.revertedWith("ERC20: decreased allowance below zero");
        });

        it("decreases allowance of spender", async () => {
          const prevAllowance: BigNumber = await afterLife.allowance(
            deployer.address,
            account_1.address
          );

          const tx: ContractTransaction = await afterLife.decreaseAllowance(
            account_1.address,
            amount
          );
          await tx.wait(1);

          const currentAllowance: BigNumber = await afterLife.allowance(
            deployer.address,
            account_1.address
          );

          expect(currentAllowance).to.equal(prevAllowance.sub(amount));
        });

        it("emits event on decrease", async () => {
          await expect(
            afterLife.increaseAllowance(account_1.address, amount)
          ).to.emit(afterLife, "Approval");
        });
      });
    });
