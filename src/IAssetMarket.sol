// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.16;

/**
 * @dev Interface for a Bionet Market
 */
interface IAssetMarket {
    /**
     * @dev Emitted when `registerAsset` is called
     */
    event AssetRegistered(
        address indexed assetAddress,
        uint256 licensePrice,
        uint256 ipPrice,
        bool isIPforSale
    );

    /**
     * @dev Emitted when `updateAsset` is called
     */
    event AssetUpdated(
        address indexed assetAddress,
        uint256 licensePrice,
        uint256 ipPrice,
        bool isIPforSale
    );

    /**
     * @dev Register an asset with the market.
     * @param _licensePrice price of a license in biotokens
     * @param _isIPforSale is the IP for sale?
     * @param _ipPrice the price in biotokens for the IP/Asset (if for sale)
     *
     * Should revert IF:
     * - the caller is the zero address
     * - the calling address is NOT an asset contract
     * - the asset has already been registered
     */
    function registerAsset(
        uint256 _licensePrice,
        bool _isIPforSale,
        uint256 _ipPrice
    ) external;

    /**
     * @dev Update an existing asset
     * @param _licensePrice price of a license in biotokens
     * @param _isIPforSale is the IP for sale
     * @param _ipPrice the price in biotokens for the IP/asset (if for sale)
     *
     * Should revert IF:
     * - the caller is the zero address
     * - the asset doesn't exist
     * - the caller is NOT the asset owner
     */
    function updateAsset(
        uint256 _licensePrice,
        bool _isIPforSale,
        uint256 _ipPrice
    ) external;

    /**
     * @dev Called to purchase the Asset
     * @param _asset is the address of the asset to buy
     *
     * should revert IF:
     * - the caller is the zero address
     * - the asset doesn't exist
     * - the asset is NOT for sale
     * - the _asset address is NOT an Asset contract
     * - the buyer does NOT have enough biotokens for the price
     * - the biotoken xfer fails
     */
    function buyAsset(address _asset) external;

    /**
     * @dev Called to purchase `_qty` of licenses
     * @param _asset the address of the asset to buy
     * @param _qty the number of licenses to purchase
     *
     * should revert IF:
     * - the caller is the zero address
     * - the asset doesn't exist
     * - the _asset address is NOT an Asset contract
     * - there are NOT enough licenses available for the requested _qty
     * - the buyer doesn't have enough biotokens for the purchase
     * - the biotoken xfer fails
     */
    function buyLicense(address _asset, uint256 _qty) external;
}
