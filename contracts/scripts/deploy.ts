import { ethers } from "hardhat";

const main = async () => {
  const domainContractFactory = await ethers.getContractFactory('DacadeENS');
  const domainContract = await domainContractFactory.deploy("dacade");
  await domainContract.deployed();

  console.log("Contract deployed to:", domainContract.address);

  let txn = await domainContract.register("banana",  {value: ethers.utils.parseEther('0.1')});
  await txn.wait();
  console.log("Minted domain banana.dacade");

  txn = await domainContract.setRecord("banana", "Am I a banana or a dacade??");
  await txn.wait();
  console.log("Set record for banana.dacade");

  const address = await domainContract.getAddress("banana");
  console.log("Owner of domain banana:", address);

  const balance = await ethers.provider.getBalance(domainContract.address);
  console.log("Contract balance:", ethers.utils.formatEther(balance));
}

const deploy = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

deploy();
/*
0xE8327642Ce5614236dB56f493a74feeB7D857d4D
*/