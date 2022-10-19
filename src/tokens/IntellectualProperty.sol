// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.16;

import "openzepplin/token/ERC1155/ERC1155.sol";
import "openzepplin/security/ReentrancyGuard.sol";

import "../IMarket.sol";

/**
 * @notice Represents Intellectual Property and potentially many copyright (like) licenses.
 * A user can create an instance of this contract to assert ownership of their
 * IP (think NFT).  The address of this contract represents a globally unique identifier
 * for the IP.
 *
 * Through this contract an owner can mint and sell copyright licenses for the given IP.
 * Sales and transfers are handled via an independent 'Market' contract.  The owner can
 * also (optionally) sell and transfer the IP itself through the market.
 *
 * Terms and conditions of the associated IP/Licenses are linked to this the contract
 * via a URL with strucutured metadata in the JSON format (todo).
 *
 * All sales are conducted via BioTokens.
 *
 * @dev There's a single NFT represented by the id 1
 * There can be many licenses represented by the id 2
 *
 * TODO: allow the owner to 'mint' more licenses (ID 2)
 *
 * Inspired by the Ocean Protocol
 */
contract IntellectualProperty is ERC1155, ReentrancyGuard {
    // token IDs
    uint256 public constant IP = 1;
    uint256 public constant LICENSE = 2;

    // IP owner
    address private _owner;

    // the market
    IMarket private market;

    modifier onlyOwner() {
        require(msg.sender == _owner, "IP: not the owner");
        _;
    }

    /**
     * @notice Create the IP, minting it to the address of the '_ipowner'. See Factory.sol
     * @param _ipowner the caller to the Factory
     * @param _uri the URI to the json file with metadata on this IP
     * @param _market address of the deployed Market contract. See Factory
     */
    constructor(
        address _ipowner,
        string memory _uri,
        address _market
    ) ERC1155(_uri) {
        // We don't use msg.sender as the owner because the factory is
        // intended to create this contract - which would incorrectly make it the caller.
        _owner = _ipowner;
        market = IMarket(_market);
        //market = _market;
        // mint *only* 1 IP to the owner (NFT)
        _mint(_owner, IP, 1, "");
    }

    /**
     * @notice Register the IP with the market.  Can only be called once for a
     * given IP.
     * @param _licenseQty the number of licenses to mint
     * @param _licensePrice the price per license in biotokens
     * @param _isIPForSale is the IP available to buy
     * @param _ipPrice cost of the IP in biotokens IFF it's for sale
     */
    function register(
        uint256 _licenseQty,
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external onlyOwner nonReentrant {
        // NOTE: We use nonReentrant here because we're updating state
        // *after* we make an external call

        // mint the licenses
        _mint(_owner, LICENSE, _licenseQty, "");

        // Register with the market. It will revert IF the IP has
        // already been registered
        market.registerProduct(_licensePrice, _isIPForSale, _ipPrice);

        // Approve the market to trade on our behalf.  Also see _afterTransfer hook below
        setApprovalForAll(address(market), true);
    }

    /**
     * @notice Update information about the product in the market
     * @param _licensePrice the price per license in biotokens
     * @param _isIPForSale is the IP available to buy
     * @param _ipPrice cost of the IP in biotokens IFF it's for sale
     */
    function update(
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external onlyOwner {
        // Will revert if the caller is not the owner of the IP
        market.updateProduct(_licensePrice, _isIPForSale, _ipPrice);
    }

    function stopSelling() public onlyOwner {
        // TODO: Don't delete the product just flag in storage??
    }

    // ** Helpers ** //

    /**
     * @notice Return the owner of the IP
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @notice Return the number of licenses that are available by the owner
     */
    function availableLicenses() public view returns (uint256) {
        return balanceOf(_owner, LICENSE);
    }

    /**
     * @notice Return the URI of the metadata for this IP.
     */
    function licenseURI() public view returns (string memory) {
        return uri(1);
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
