//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/utils/MerkleProof.sol";
import "hardhat/console.sol";

contract NFTDrop is ERC721Royalty, ReentrancyGuard, Ownable {
    ///@dev masterMinter
    address public immutable preMinter;

    ///@dev royalty owner
    address public royaltyOwner;

    /**
     *@dev mint phases
     *@param  PRE_MINTING pre minting phase
     *@param WHITELIST whitelist phase
     *@param PUBLIC public minting phase
     */
    enum MintPhase {
        PRE_MINTING,
        WHITELIST,
        PUBLIC
    }

    ///@dev address => bool
    mapping(address => bool) whiteList;

    ///@dev address => owned nft amount
    mapping(address => uint256) ownedNFTs;
    
    ///@dev maximum amount
    uint256 public constant maxAmount = 999;

    ///@dev ntf price
    uint256 public constant nftPrice = 0.06 ether;

    ///@dev total supply
    uint256 public tokenIdTracker = 1;
        
    ///@dev preminting id
    uint256 public preMintingId = 20;

    ///@dev royalty fee = 6 %
    uint96 public royaltyFee = 6;

    ///@dev baseTokenURI
    string public baseTokenURI;

    ///@dev current phase
    MintPhase currentPhase;

    ///@dev merkle proof
    bytes32[] public merkleProof;

    ///@dev merkel root
    bytes32 public merkleRoot;

    ///@dev Mint event
    event Minted(address minter, uint256 id);

    /** 
     * @dev constructor
     * @param _name name
     * @param _symbol symbol
     * @param baseURI base URI for token.
     */
    constructor(
      string memory _name,
      string memory _symbol,
      string memory baseURI
    )
        ERC721(_name, _symbol)
    {
        setBaseURI(baseURI);
        preMinter = _msgSender();
        royaltyOwner = _msgSender();
    }

    modifier saleIsOpen() {
        require(tokenIdTracker <= maxAmount, "NFTDrop: maximum amount exceeded");
        _;
    }

    /**
     * @dev mint card token to contract
     * @param amount amount to be minted
     */
    function mint(uint256 amount) external payable nonReentrant saleIsOpen {
        require(msg.value >= nftPrice, "NFTDrop: not enough price");
        require(tokenIdTracker + amount <= maxAmount, "NFTDrop: can't be grater that maxAmount(999)");

        uint256 id = tokenIdTracker;
        if (currentPhase == MintPhase.PRE_MINTING) {                            //pre mint phase
            require(_msgSender() == preMinter, "NFTDrop: not allowed preminter");
            id = 20;
            _setTokenRoyalty(id, royaltyOwner, royaltyFee);

            _safeMint(_msgSender(), id);
            emit Minted(_msgSender(), id);
        } else if (id != preMintingId && id <= 501 && currentPhase == MintPhase.WHITELIST) {        //whitelist phase
            require(!whiteList[_msgSender()], "NFTDrop: already claimed address");
            require(merkleProof.length != 0 && merkleRoot.length != 0, "NFTDrop: hash data should be set");

            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "NFTDrop: invalid proof");
            
            _setTokenRoyalty(id, royaltyOwner, royaltyFee);

            _safeMint(_msgSender(), id);
            emit Minted(_msgSender(), id);

            whiteList[_msgSender()] = true;

            if (id == preMintingId - 1)
                tokenIdTracker += 2;
            else
                tokenIdTracker += 1;
        } else if (currentPhase == MintPhase.PUBLIC) {             //public mint phase
            require(ownedNFTs[_msgSender()] + amount <= 5, "NFTDrop: can mint 5 NFTs");

            for (uint256 i = 0; i < amount; i++) {
                _setTokenRoyalty(id, royaltyOwner, royaltyFee);
              
                _safeMint(_msgSender(), id);
                emit Minted(_msgSender(), id);

                id += 1;
            }
            ownedNFTs[_msgSender()] += amount;
            tokenIdTracker += amount;
        }
    }

    /**
     * @dev withdraw current balance: only owner can call
     * @param recepient address of recepient
     */
    function withdraw(address payable recepient) external onlyOwner nonReentrant {
        require(recepient != address(0), "NFTDrop: invalid recipent address");
        
        uint256 currentBalance = getBalance();

        (bool success, ) = recepient.call{ value: currentBalance }("");
        require(success, "NFTDrop: failed to send ethers");
    }

    /**
     * @dev set current mint phase
     * @param newPhase one of mint phases
     */
    function setPhase(MintPhase newPhase) external onlyOwner {
        if (newPhase == MintPhase.WHITELIST) {
            require(currentPhase == MintPhase.PRE_MINTING, "NFTDrop: should be on the pre-minting phase");
        } else if (newPhase == MintPhase.PUBLIC) {
            require(currentPhase == MintPhase.WHITELIST, "NFTDrop: should be on the whitelist phase");
        }

        currentPhase = newPhase;
    }

    /**
     * @dev  set some hash date to verify
     * @param _merkleProof array of hashed whitelist addresses
     * @param _merkleRoot the root hash of a Merkle Tree
     */
    function setHashData(bytes32[] calldata _merkleProof, bytes32 _merkleRoot) external onlyOwner {
        merkleProof = _merkleProof;
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev set new royalty owner
     * @param newRoyaltyOwner new owner
     */
    function setRoyaltyOwner(address newRoyaltyOwner) external onlyOwner {
        require(newRoyaltyOwner != address(0), "NFTDrop: invalid address");
        royaltyOwner = newRoyaltyOwner;
    }

    ///@dev get current balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @dev set baseURI
     * @param baseURI baseURI string
     */
    function setBaseURI(string memory baseURI) public {
        baseTokenURI  = baseURI;
    }

    ///@dev override _baseURI, return baseTokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. It is overriden by 100 instead of 10000
     */
    function _feeDenominator() internal pure virtual override returns (uint96) {
        return 100;
    }
}
