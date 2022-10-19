// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation

pragma solidity ^0.8.16;

/**
 * @notice Initial generic interface for a market.
 */
interface IMarket {
    function registerProduct(
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external;

    function updateProduct(
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external;

    function removeProductFromMarket() external;
}
