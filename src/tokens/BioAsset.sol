// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.16;

import "openzepplin/token/ERC1155/ERC1155.sol";
import "openzepplin/security/ReentrancyGuard.sol";

import "./IBioAsset.sol";
import "../IAssetMarket.sol";

/**
 * @notice Represents an asset.  Used to track ownership, provenance, and transfers.
 * A user can create an instance of this contract to assert ownership of their Asset(think NFT).
 * For now, the address of this contract represents it's globally unique identifier
 *
 * Through this contract an owner can mint and sell copyright licenses.
 * Sales and transfers are handled via an independent 'Market' contract.  The owner can
 * also (optionally) sell and transfer the Asset (and it's IP) through the market.
 *
 * Metadata about the asset, such as terms/conditions, etc... are embedded in the event
 * log for the contract
 *
 * All sales of an asset are conducted with BioTokens.
 *
 * @dev There's a single NFT represented by the id 1
 * There can be many licenses represented by the id 2
 *
 * TODO: allow the owner to 'mint' more licenses (ID 2)
 *
 * Inspired by the Ocean Protocol
 */
contract BioAsset is ERC1155, IBioAsset, ReentrancyGuard {
    // Token IDs
    uint8 public constant IP = 1;
    uint8 public constant LICENSE = 2;

    // Asset owner
    address private _owner;

    // Market the asset uses
    IAssetMarket private market;

    modifier onlyOwner() {
        require(msg.sender == _owner, "IP: not the owner");
        _;
    }

    /**
     * @notice Create an Asset, minting it to the address of the ' _assetOwner'. See Factory.sol
     * @param  _assetOwner based on the caller to the Factory
     * @param _uri the URI to the metadata of this asset. See indexer API
     * @param _market address of the deployed Market contract. See Factory
     */
    constructor(
        address _assetOwner,
        string memory _uri,
        address _market
    ) ERC1155(_uri) {
        // We don't use msg.sender as the owner because the factory is
        // intended to create this contract - which would incorrectly make it the caller.
        _owner = _assetOwner;
        market = IAssetMarket(_market);
        // mint *only* 1 IP to the owner (NFT)
        _mint(_owner, IP, 1, "");
    }

    /**
     * @dev See {IBioAsset}.
     */
    function registerWithMarket(
        uint256 _licenseQty,
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external onlyOwner {
        // NOTE: We use nonReentrant here because we're updating state
        // *after* we make an external call

        // mint the licenses
        _mint(_owner, LICENSE, _licenseQty, "");

        // Register with the market. It will revert IF the IP has
        // already been registered
        market.registerAsset(_licensePrice, _isIPForSale, _ipPrice);

        // Approve the market to trade on our behalf.  Also see _afterTransfer hook below
        setApprovalForAll(address(market), true);
    }

    /**
     * @dev See {IBioAsset}.
     */
    function updateWithMarket(
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external onlyOwner {
        // Will revert if the caller is not the owner of the IP
        market.updateAsset(_licensePrice, _isIPForSale, _ipPrice);
    }

    /**
     * @dev See {IBioAsset}.
     */
    function setMetaData(bytes calldata data) external onlyOwner {
        emit MetaDataCreated(data);
    }

    /**
     * @dev See {IBioAsset}.
     */
    function updateMetaData(bytes calldata data) external onlyOwner {
        emit MetaDataUpdated(data);
    }

    /**
     * @dev See {IBioAsset}.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev See {IBioAsset}.
     */
    function availableLicenses() public view returns (uint256) {
        return balanceOf(_owner, LICENSE);
    }

    // internal hook on transfer to track IP owners
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory, /*amounts*/
        bytes memory /*data*/
    ) internal virtual override {
        // after an IP token transfer we need
        // to update some properties...
        if (ids[0] == IP) {
            // IF this is an IP id call, change the owner to the buyer
            // this would be from an IP sale
            _owner = to;
            // remove the approval for the previous owner
            _setApprovalForAll(from, operator, false);
            // add the approval for the current owner
            _setApprovalForAll(to, operator, true);
            // in both cases above 'operator' is the market
        }
    }
}
