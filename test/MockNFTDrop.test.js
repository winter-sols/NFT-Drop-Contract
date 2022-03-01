const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')

describe("Mock NFT Drop", async () => {
  before(async () => {
    const users = await ethers.getSigners()
    const [preMinter, alice, bob, carl, dom, eric, felix] = users
    this.preMinter = preMinter
    this.alice = alice
    this.bob = bob
    this.carl = carl
    this.dom = dom
    this.eric = eric
    this.felix = felix

    this.nftPrice = ethers.utils.parseEther("0.06")
    this.gasFee = ethers.utils.parseEther("0.00000000000000001")
    this.maxAmount = 13
    this.preMintingId = 2

    this.PRE_MINTING_PHASE = 0
    this.WHITELIST_PHASE = 1
    this.PUBLIC_MINTING_PHASE = 2
    
    this.whitelistAddresses = [
      this.alice.address,
      this.bob.address,
      this.carl.address,
      this.dom.address
    ]
    
    this.leafNode = this.whitelistAddresses.map(addr => keccak256(addr))
    this.merkleTree = new MerkleTree(this.leafNode, keccak256, { sortPairs: true })
    this.rootHash = this.merkleTree.getHexRoot()

    // Deploy NFTDrop contract
    const NFTDrop = await ethers.getContractFactory("MockNFTDrop")
    this.nftDrop = await NFTDrop.deploy("NFTDrop", "ND", "http:/capsulecrop/")
  })

  it("Mint fails: minter should send more than a NFT price: nft price + gas fee", async () => {
    await expect(this.nftDrop.connect(this.preMinter).mint(1, { value: this.nftPrice }))
      .to.revertedWith("NFTDrop: not enough price")
  })

  it("Mint fails: minting amount should be less than maximum amount", async ()=> {
    await expect(this.nftDrop.connect(this.preMinter).mint(
      this.maxAmount + 1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: can't be grater that maxAmount(13)")
  })

  it("In the pre-minting phase, mint fails : only pre-minter is able to mint NFT", async () => {
    await expect(this.nftDrop.connect(this.alice).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: not allowed preminter")
  })

  it("In the pre-minting phase, mint succeeds: mint #20 nft by the pre-minter", async () => {
    await expect(this.nftDrop.connect(this.preMinter).mint(
      1,
      { value: this.nftPrice + this.gasFee}
    )).emit(this.nftDrop, "Minted")
      .withArgs(this.preMinter.address, this.preMintingId)
  })

  it("Tranforming to public whitelist fails: only owner is able to set phase", async () => {
    await expect(this.nftDrop.connect(this.alice).setPhase(this.PUBLIC_MINTING_PHASE))
      .revertedWith("Ownable: caller is not the owner")
  })

  it("Tranforming to public phase fails: current phase should be the whitelist phase", async () => {
    await expect(this.nftDrop.connect(this.preMinter).setPhase(this.PUBLIC_MINTING_PHASE))
      .to.revertedWith("NFTDrop: should be on the whitelist phase")
  })

  it("Transforming to whitelist phase succeeds: per-minter set current phase as WHITELIST", async () => {
    await expect(this.nftDrop.connect(this.preMinter).setPhase(this.WHITELIST_PHASE))
  })

  
})