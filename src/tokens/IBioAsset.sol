// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.16;

/**
 * @dev Asset interface to interact with the Bionet.  This should be
 * implemented with an ERC-1155 or 721 contact.
 */
interface IBioAsset {
    /**
     * @dev Emitted when owner calls `setMetaData`
     */
    event MetaDataCreated(bytes data);

    /**
     * @dev Emitted when owner calls `updateMetaData`
     */
    event MetaDataUpdated(bytes data);

    /**
     * @dev Sets the metadata in the event log (via event above).
     * `data` should follow a defined format that can be extracted
     * off-chain
     */
    function setMetaData(bytes calldata data) external;

    /**
     * @dev Updates the metadata via the event log.
     */
    function updateMetaData(bytes calldata data) external;

    /**
     * @dev Register the asset with the market.  Can only be called once - enforced
     * via the market.
     * @param _licenseQty the number of licenses to mint
     * @param _licensePrice the price per license in biotokens
     * @param _isIPForSale is the IP available to buy
     * @param _ipPrice cost of the IP in biotokens IFF it's for sale
     */
    function registerWithMarket(
        uint256 _licenseQty,
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external;

    /**
     * @dev Update asset information in the market
     * @param _licensePrice the price per license in biotokens
     * @param _isIPForSale is the IP available to buy
     * @param _ipPrice cost of the IP in biotokens IFF it's for sale
     */
    function updateWithMarket(
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external;

    /**
     * @dev Return the owner of the Asset
     */
    function owner() external view returns (address);

    /**
     * @dev Return the number of licenses that are available by the owner for sale
     */
    function availableLicenses() external view returns (uint256);
}
