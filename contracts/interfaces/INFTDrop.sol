//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTDrop {

    /**
     * @dev token info
     * @param minter nft owner wallet address
     * @param name nft name
     * @param price nft price
     */
    struct TokenInfo {
        address minter;
        string name;
        uint256 price;
    }

    /**
     * @dev mint card token to contract
     * @param name nft name
     * @param price nft price
     * @param amount amount of nfts to be minted
     */
    function mint(
        string calldata name,
        uint256 price,
        uint256 amount
    ) external payable;

    /**
     * @dev  add minter address to whitelist
     * @param minters array of minter wallet addresses
     */
    function addToWhitelist(address[] memory minters) external;

    /**
     * @dev  remove minter address from whitelist
     * @param minters array of minter wallet address
     */
    function removeFromWhiteList(address[] memory minters) external;
}