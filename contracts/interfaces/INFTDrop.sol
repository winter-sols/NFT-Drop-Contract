//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTDrop {
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
    /**
     * @dev mint card token to contract
     * @param amount amount of nfts to be minted
     */
    function mint(
        uint256 amount
    ) external payable;

    /**
     * @dev  set some hash date to verify
     * @param merkleProof array of hashed whitelist addresses
     * @param merkleRoot the root hash of a Merkle Tree
     */
    function setHashData(bytes32[] memory merkleProof, bytes32 merkleRoot) external;

    /**
     * @dev set current mint phase
     * @param phase one of mint phases
     */
    function setPhase(MintPhase phase) external;
}