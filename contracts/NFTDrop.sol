//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/utils/MerkleProof.sol";
import "hardhat/console.sol";

contract NFTDrop is ERC721Enumerable, ReentrancyGuard, Ownable {

    ///@dev masterMinter
    address public preMinter;
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
    uint256 public maxAmount = 999;

    ///@dev total supply
    uint256 public tokenIdTracker = 1;

    ///@dev ntf price
    uint256 public nftPrice = 0.06* 10e18 wei;

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
        require(msg.value > nftPrice, "NFTDrop: not enough price");
        require(tokenIdTracker + amount <= maxAmount, "NFTDrop: can't be grater that maxAmount(999)");

        uint256 id = tokenIdTracker;
        if (currentPhase == MintPhase.PRE_MINTING) {                            //pre mint phase
            require(_msgSender() == preMinter, "NFTDrop: not allowed preminter");
            id = 20;

            _safeMint(_msgSender(), id);
            emit Minted(_msgSender(), id);
        } else if (id == 20 && currentPhase == MintPhase.WHITELIST) {
            tokenIdTracker += 1;
        } else if (id != 20 && id <= 501 && currentPhase == MintPhase.WHITELIST) {        //whitelist phase
            require(!whiteList[_msgSender()], "NFTDrop: already claimed address");

            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "NFTDrop: invalid proof");

            whiteList[_msgSender()] = true;
            tokenIdTracker += 1;

            _safeMint(_msgSender(), id);
            emit Minted(_msgSender(), id);
        } else if (id > 501 && currentPhase == MintPhase.PUBLIC) {             //public mint phase
            require(ownedNFTs[_msgSender()] + amount <= 5, "NFTDrop: can mint 5 NFTs");

            for (uint256 i = 0; i < amount; i++) {
                _safeMint(_msgSender(), id);
                emit Minted(_msgSender(), id);

                id += 1;
            }
            ownedNFTs[_msgSender()] += amount;
            tokenIdTracker += amount;
        }
    }

    function setPhase(MintPhase newPhase) external onlyOwner {
        if (newPhase == MintPhase.WHITELIST) {
            require(currentPhase == MintPhase.PRE_MINTING, "NFTDrop: should be on the pre-minting phase");
        } else if (newPhase == MintPhase.PUBLIC) {
            require(currentPhase == MintPhase.WHITELIST, "NFTDrop: should be on the whitelist phase");
        }

        currentPhase = newPhase;
    }

    function setHashData(bytes32[] memory _merkleProof, bytes32 _merkleRoot) external onlyOwner {
        merkleProof = _merkleProof;
        merkleRoot = _merkleRoot;
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
}