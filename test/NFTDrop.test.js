const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Drop", async () => {
  before(async () => {
    const users = await ethers.getSigners()
    const [preMinter, alice, bob] = users
    this.preMinter = preMinter
    this.alice = alice
    this.bob = bob

    // Deploy NFTDrop contract
    const NFTDrop = await ethers.getContractFactory("NFTDrop")
    this.nftDrop = await NFTDrop.deploy("NFTDrop", "ND", "http:/capsulecrop/")
  })
})