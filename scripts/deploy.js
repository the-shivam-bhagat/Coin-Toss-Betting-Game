const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Deploying without inputs
  const CoinToss = await ethers.getContractFactory("CoinToss");
  const coinToss = await CoinToss.deploy();
  await coinToss.deployed();

  console.log("Contract deployed at:", coinToss.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error("Deployment error:", error);
    process.exit(1);
  });
