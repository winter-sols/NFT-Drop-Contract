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
    await expect(this.nftDrop.connect(this.preMinter).mint(1, { value: ethers.utils.parseEther("0.059") }))
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

  it("Tranforming to public phase fails: only owner is able to set phase", async () => {
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

  it("In whitelist phase, mint fails: hash data should be set before minting", async () => {
    await expect(this.nftDrop.connect(this.alice).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: hash data should be set")
  })

  //To mint as a whitelister, it is necessary to set hash data amd mint nft with verification: Alice mint a nft
  it("In whitelist phase, set hash data", async () => {
    const claimer = this.leafNode[0]   // For alice
    const merkleProof = this.merkleTree.getHexProof(claimer)
    await expect(this.nftDrop.connect(this.preMinter).setHashData(merkleProof, this.rootHash))
  })

  it("In whitelist phase, mint fails: whitelister can only mint one NFT", async () => {
    await expect(this.nftDrop.connect(this.carl).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: invalid proof")
  })

  it("In whitelist phase, mint succeeds", async () => {
    await expect(this.nftDrop.connect(this.alice).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).emit(this.nftDrop, "Minted")
      .withArgs(this.alice.address, 1)
  })

  it("In whitelist phase, mint fails: can only mint once", async () => {
    await expect(this.nftDrop.connect(this.alice).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: already claimed address")
  })
  //-----------Alice-----------------
  
  // Bob mint a nft
  it("In whitelist phase, set hash data", async () => {
    const claimer = this.leafNode[1]   // For bob
    const merkleProof = this.merkleTree.getHexProof(claimer)
    await expect(this.nftDrop.connect(this.preMinter).setHashData(merkleProof, this.rootHash))
  })

  it("In whitelist phase, mint succeeds", async () => {
    await expect(this.nftDrop.connect(this.bob).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).emit(this.nftDrop, "Minted")
      .withArgs(this.bob.address, 3)
  })

  it("In whitelist phase, mint fails: can only mint once", async () => {
    await expect(this.nftDrop.connect(this.bob).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: already claimed address")
  })
  // -----------Bob-------------------

  // Carl mint a nft
  it("In whitelist phase, set hash data", async () => {
    const claimer = this.leafNode[2]   // For carl
    const merkleProof = this.merkleTree.getHexProof(claimer)
    await expect(this.nftDrop.connect(this.preMinter).setHashData(merkleProof, this.rootHash))
  })

  it("In whitelist phase, mint succeeds", async () => {
    await expect(this.nftDrop.connect(this.carl).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).emit(this.nftDrop, "Minted")
      .withArgs(this.carl.address, 4)
  })

  it("In whitelist phase, mint fails: can only mint once", async () => {
    await expect(this.nftDrop.connect(this.carl).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: already claimed address")
  })
  // -----------Carl-------------------

  it("Withdraw fails: only owner can withdraw", async () => {
    await expect(this.nftDrop.connect(this.carl).withdraw(this.carl.address))
      .to.revertedWith("Ownable: caller is not the owner")
  })

  it("Withdraw fails: recepient address should exist", async () => {
    await expect(this.nftDrop.connect(this.preMinter).withdraw(ethers.constants.AddressZero))
      .to.revertedWith("NFTDrop: invalid recipent address")
  })

  it("Withdraw succeeds: contract's balance to a recepient", async () => {
    await this.nftDrop.connect(this.preMinter).withdraw(this.carl.address)
  })

  // Dom mint a nft
  it("In whitelist phase, set hash data", async () => {
    const claimer = this.leafNode[3]   // For carl
    const merkleProof = this.merkleTree.getHexProof(claimer)
    await expect(this.nftDrop.connect(this.preMinter).setHashData(merkleProof, this.rootHash))
  })

  it("In whitelist phase, mint succeeds", async () => {
    await expect(this.nftDrop.connect(this.dom).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).emit(this.nftDrop, "Minted")
      .withArgs(this.dom.address, 5)
  })
  // -----------Dom-------------------

  it("Tranforming to public phase succeeds", async () => {
    await expect(this.nftDrop.connect(this.preMinter).setPhase(this.PUBLIC_MINTING_PHASE))
  })

  it("In public phase, mint succeeds", async () => {
    await expect(this.nftDrop.connect(this.eric).mint(
      5,
      { value: this.nftPrice + this.gasFee }
    )).emit(this.nftDrop, "Minted")
      .withArgs(this.eric.address, 10)
  })

  it("In public phase, mint fails: a minter can't mint over 5 NFTs", async () => {
    await expect(this.nftDrop.connect(this.eric).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: can mint 5 NFTs")
  })

  it("In public phase, mint succeeds", async () => {
    await expect(this.nftDrop.connect(this.felix).mint(
      3,
      { value: this.nftPrice + this.gasFee }
    )).emit(this.nftDrop, "Minted")
      .withArgs(this.felix.address, 13)
  })

  it("In public phase, mint fails: can't be over maximum amount of NFTs", async () => {
    await expect(this.nftDrop.connect(this.felix).mint(
      1,
      { value: this.nftPrice + this.gasFee }
    )).to.revertedWith("NFTDrop: can't be grater that maxAmount(13)")
  })

  it("Setting Royalty Owner fails: only owner can set new royalty owner", async () => {
    await expect(this.nftDrop.connect(this.felix).setRoyaltyOwner(this.felix.address))
      .to.revertedWith("Ownable: caller is not the owner")
  })

  it("Setting Royalty Owner fails: can set valid address as a new royalty owner", async () => {
    await expect(this.nftDrop.connect(this.preMinter).setRoyaltyOwner(ethers.constants.AddressZero))
      .to.revertedWith("NFTDrop: invalid address")
  })
})
