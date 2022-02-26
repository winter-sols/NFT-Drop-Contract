//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NFTDrop is ERC721Enumerable {

    ///@dev masterMinter
    address public masterMinter;

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
        uint16 id;
        uint256 price;
    }

    ///@dev id => TokenInfo
    mapping(uint16 => TokenInfo) tokenInfos;

    ///@dev mint fee
    uint256 public mintFee = 0.06 ether;

    ///@dev baseTokenURI
    string public baseTokenURI;

    ///@dev Mint event
    event Minted(address minter, uint16 id);

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
        masterMinter = _msgSender();
        setBaseURI(baseURI);
    }

    /**
     * @dev mint card token to contract
     * @param minter owner wallet address
     * @param name nft name
     * @param id nft id
     * @param price nft price
     */
    function mint(address minter, string calldata name, uint16 id, uint256 price) external payable {
        require(minter != address(0), "NFTDrop: invalid minter address");
        require(price > 0, "NFTDrop: invalid NFT price");
        require(bytes(name).length > 0, "NFTDrop: no NFT name");
        require(tokenInfos[id].minter == address(0), "NFTDrop: already exists");
        require(msg.value >= mintFee, "NFTDrop: not enough minting fee");

        tokenInfos[id] = TokenInfo(
            minter,
            name,
            id,
            price
        );

        //TODO premint #20, whitelist, public mint


        _safeMint(minter, id);
        emit Minted(minter, id);

    }


    function setBaseURI(string memory baseURI) public {
        baseTokenURI  = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}