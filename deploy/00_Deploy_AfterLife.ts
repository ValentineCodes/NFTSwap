import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployments, getNamedAccounts, network } from "hardhat";

import {
  developmentChains,
  VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config";
import { verify } from "../helper-functions";

const deployAfterLife: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId: number | undefined = network.config.chainId;

  let afterLifeAddress: string = "";

  if (!chainId) return;

  const waitBlockConfirmations: number = developmentChains.includes(
    network.name
  )
    ? 1
    : VERIFICATION_BLOCK_CONFIRMATIONS;

  /* Deploy contract */
  try {
    log("Deploying...");

    const afterLife = await deploy("AfterLife", {
      from: deployer,
      args: [],
      log: true,
      waitConfirmations: waitBlockConfirmations,
    });

    afterLifeAddress = afterLife.address;

    log(`Deployed contract to ${afterLife.address} on ${network.name} network`);
  } catch (error) {
    log("Failed to deploy contract");
    console.error(error);
  }

  /* Verify contract */
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(afterLifeAddress, []);

    log("Verification successful");
  }
};

export default deployAfterLife;

deployAfterLife.tags = ["all", "afterLife"];
