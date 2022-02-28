//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NFTDrop is ERC721Enumerable, ReentrancyGuard, Ownable {

    ///@dev masterMinter
    address public preMinter;
    /**
     *@dev mint phases
     *@param  pre pre minting phase
     *@param WhiteList whitelist phase
     *@param Public public minting phase
     */
    enum MintPhases {
        Pre,
        WhiteList,
        Public
    }

    /**
     * @dev token info
     * @param minter nft owner wallet address
     * @param name nft name
     * @param id nft id
     * @param price nft price
     */
    struct TokenInfo {
        address minter;
        string name;
        uint256 price;
    }

    ///@dev id => TokenInfo
    mapping(uint256 => TokenInfo) tokenInfos;

    ///@dev address => bool
    mapping(address => bool) whiteList;

    ///@dev address => owned nft amount
    mapping(address => uint256) ownedNFTs;
    
    ///@dev maximum amount
    uint256 public maxAmount = 999;

    ///@dev total supply
    uint256 public tokenIdTracker;

    ///@dev baseTokenURI
    string public baseTokenURI;

    ///@dev preMined flag
    bool public preMinted;

    ///@dev preMined flag
    bool public whiteListFinished;

    ///@dev Mint event
    event Minted(address minter, uint256 id);

    event WhiteListAdded(address minter);

    event WhiteListRemoved(address minter);

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
     * @param name nft name
     * @param price nft price
     * @param amount amount to be minted
     */
    function mint(string calldata name, uint256 price, uint256 amount) external nonReentrant saleIsOpen {
        require(price > 0, "NFTDrop: invalid NFT price");
        require(bytes(name).length > 0, "NFTDrop: no NFT name");

        uint256 id = tokenIdTracker;

        //TODO premint #20, whitelist, public mint

        if (id != 20 && id < 521 && preMinted) {        //whitelist phase
            require(whiteList[_msgSender()], "NFTDrop: not whitelised address");
            require(ownedNFTs[_msgSender()] == 0, "NFTDrop: already have a NFT minted");
            require(amount == 1, "NFTDrop: not allowed mint amount");

            if (id == 520) whiteListFinished = true;

            tokenInfos[id] = TokenInfo(
                _msgSender(),
                name,
                price
            );
            ownedNFTs[_msgSender()] += amount;
            tokenIdTracker += amount;

            _safeMint(_msgSender(), id);
            emit Minted(_msgSender(), id);
        } else if (id >= 521 && whiteListFinished) {             //public mint phase
            require(ownedNFTs[_msgSender()] + amount <= 5, "NFTDrop: can mint 5 NFTs");

            for (uint256 i = 0; i < amount; i++) {
                tokenInfos[id] = TokenInfo(
                    _msgSender(),
                    name,
                    price
                );

                _safeMint(_msgSender(), id);
                emit Minted(_msgSender(), id);

                id += 1;
            }
            ownedNFTs[_msgSender()] += amount;
            tokenIdTracker += amount;
        } else {                            //pre mint phase
            require(_msgSender() == preMinter, "NFTDrop: not allowed preminter");
            id = 20;
            tokenInfos[id] = TokenInfo(
                _msgSender(),
                name,
                price
            );
            preMinted = true;

            _safeMint(_msgSender(), id);
            emit Minted(_msgSender(), id);
        }

    }

    /**
     * @dev  add minter addresses to whitelist
     * @param minters array of minter wallet address
     */
    function addToWhiteList(address[] memory minters) external onlyOwner {
        for (uint256 i = 0; i < minters.length; i ++) {
            if (minters[i] != address(0)) whiteList[minters[i]] = true;

            emit WhiteListAdded(minters[i]);
        }
    }

    /**
     * @dev  remove minter addresses from whitelist
     * @param minters array of minter wallet address
     */
    function removeFromWhiteList(address[] memory minters) external onlyOwner {
        for (uint256 i = 0; i < minters.length; i ++) {
            if (minters[i] != address(0)) whiteList[minters[i]] = false;

            emit WhiteListRemoved(minters[i]);
        }
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