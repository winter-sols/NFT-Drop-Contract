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
     * @dev withdraw current balance: only owner can call
     * @param recepient payable address of recepient
     */
    function withdraw(address payable recepient) external;

    /**
     * @dev  set some hash date to verify
     * @param _merkleProof array of hashed whitelist addresses
     * @param _merkleRoot the root hash of a Merkle Tree
     */
    function setHashData(bytes32[] calldata _merkleProof, bytes32 _merkleRoot) external;

    /**
     * @dev set current mint phase
     * @param newPhase one of mint phases
     */
    function setPhase(MintPhase newPhase) external;

    /**
     * @dev set new royalty owner
     * @param newRoyaltyOwner new owner
     */
    function setRoyaltyOwner(address newRoyaltyOwner) external;
}
