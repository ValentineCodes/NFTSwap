import { DeployFunction } from "hardhat-deploy/types";
import { deployments, network, ethers } from "hardhat";

import {
  developmentChains,
  VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config";
import { verify } from "../helper-functions";

const deployNFTSwap: DeployFunction = async () => {
  const { deploy, log } = deployments;
  const accounts = await ethers.getSigners();
  const chainId: number | undefined = network.config.chainId;

  let nftSwapAddress: string = "";

  if (!chainId) return;

  const waitBlockConfirmations: number = developmentChains.includes(
    network.name
  )
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS;

  /* Deploy contract */
  try {
    log("Deploying NFTSwap...");

    const nftSwap = await deploy("NFTSwap", {
      from: accounts[0].address,
      args: [],
      log: true,
      waitConfirmations: waitBlockConfirmations,
    });

    nftSwapAddress = nftSwap.address;

    log(`Deployed contract to ${nftSwap.address} on ${network.name} network`);
  } catch (error) {
    log("Failed to deploy contract");
    console.error(error);
  }

  /* Verify contract */
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    try {
      await verify(nftSwapAddress, []);

      log("Verification successful");
    } catch (error) {
      console.log(error);
    }
  }
};

export default deployNFTSwap;

module.exports.tags = ["all", "nftSwap"];
