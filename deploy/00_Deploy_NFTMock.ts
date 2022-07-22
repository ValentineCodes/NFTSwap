import { DeployFunction } from "hardhat-deploy/types";
import { deployments, network, ethers } from "hardhat";

import {
  developmentChains,
  VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config";
import { verify } from "../helper-functions";

const deployNFTMock: DeployFunction = async () => {
  const { deploy, log } = deployments;
  const accounts = await ethers.getSigners();
  const chainId: number | undefined = network.config.chainId;

  let nftMockAddress: string = "";

  if (!chainId) return;

  const waitBlockConfirmations: number = developmentChains.includes(
    network.name
  )
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS;

  /* Deploy contract */
  try {
    log("Deploying NFTMock...");

    const nftMock = await deploy("NFTMock", {
      from: accounts[0].address,
      args: [[accounts[0].address, accounts[1].address, accounts[2].address]],
      log: true,
      waitConfirmations: waitBlockConfirmations,
    });

    nftMockAddress = nftMock.address;

    log(`Deployed contract to ${nftMock.address} on ${network.name} network`);
  } catch (error) {
    log("Failed to deploy contract");
    console.error(error);
  }

  /* Verify contract */
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(nftMockAddress, []);

    log("Verification successful");
  }
};

export default deployNFTMock;

module.exports.tags = ["all", "nftMock"];
