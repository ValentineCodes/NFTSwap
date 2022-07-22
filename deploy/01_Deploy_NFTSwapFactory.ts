import { DeployFunction } from "hardhat-deploy/types";
import { deployments, network, ethers } from "hardhat";

import {
  developmentChains,
  VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config";
import { verify } from "../helper-functions";

const deployNFTSwapFactory: DeployFunction = async () => {
  const { deploy, log } = deployments;
  const accounts = await ethers.getSigners();
  const chainId: number | undefined = network.config.chainId;

  let nftSwapFactoryAddress: string = "";

  if (!chainId) return;

  const waitBlockConfirmations: number = developmentChains.includes(
    network.name
  )
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS;

  /* Deploy contract */
  try {
    log("Deploying NFTSwapFactory...");

    const nftMock = await deploy("NFTSwapFactory", {
      from: accounts[0].address,
      args: [],
      log: true,
      waitConfirmations: waitBlockConfirmations,
    });

    nftSwapFactoryAddress = nftMock.address;

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
    await verify(nftSwapFactoryAddress, []);

    log("Verification successful");
  }
};

export default deployNFTSwapFactory;

module.exports.tags = ["all", "nftSwapFactory"];
