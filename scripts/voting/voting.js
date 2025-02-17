const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Get the contract factory
  const Item = await ethers.getContractFactory("Voting");
  

  

  // Deploy the contract with the constructor parameters
  console.log("Deploying Voting contract...");
  const voting = await Item.deploy();

  // Wait for the contract to be deployed
  await voting.deployed();

  console.log("voting deployed to:", await voting.address);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
