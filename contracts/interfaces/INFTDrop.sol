//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTDrop {

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

    /**
     * @dev mint card token to contract
     * @param minter owner wallet address
     * @param name nft name
     * @param id nft id
     * @param price nft price
     */
    function mint(
        address minter,
        string calldata name,
        uint16 id,
        uint256 price
    ) external payable;
}