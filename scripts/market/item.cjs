const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Get the contract factory
  const Item = await ethers.getContractFactory("Item");
  

  // Define the parameters to pass to the constructor
  const name = "Item";
  const symbol = "ITM";
  const initialOwner = deployer.address;

  // Deploy the contract with the constructor parameters
  console.log("Deploying Item contract...");
  const item = await Item.deploy(name, symbol, initialOwner);

  // Wait for the contract to be deployed
  await item.deployed();

  console.log("Item deployed to:", await item.address);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
