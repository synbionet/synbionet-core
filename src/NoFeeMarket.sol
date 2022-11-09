// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation

pragma solidity ^0.8.16;

import "openzepplin/token/ERC20/IERC20.sol";
import "openzepplin/token/ERC1155/IERC1155.sol";
import "openzepplin/security/ReentrancyGuard.sol";
import "openzepplin/token/ERC20/utils/SafeERC20.sol";

import "./IAssetMarket.sol";
import "./tokens/BioToken.sol";
import "./tokens/BioAsset.sol";

/**
 * @dev Simple market to exchange biotokens for assets.  Collects
 * no network fees.  Used for experimentation.
 */
contract NoFeeMarket is IAssetMarket, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // access to the biotoken
    IERC20 immutable biotoken;

    // storage of IP addresses to 'product' information
    mapping(address => Product) private products;

    // container for Asset product information
    struct Product {
        address nft;
        bool isIPForSale;
        uint256 licensePrice; // in Eth for a given license
        uint256 ipPrice; // in Eth IF ipForSale is true
    }

    /**
     * @dev Create the market (once).  See Factory.sol
     * @param _biotoken address of the deployed biotoken contract
     */
    constructor(address _biotoken) {
        biotoken = IERC20(_biotoken);
    }

    /**
     * See {IAssetMarket}
     */
    function registerAsset(
        uint256 _licensePrice,
        bool _isIPforSale,
        uint256 _ipPrice
    ) external {
        address ipcaller = msg.sender;
        require(ipcaller != address(0), "Market: bad address");

        // TODO: Check for IBioToken interface

        Product storage p = products[ipcaller];
        require(p.nft == address(0), "Market: product already exists");

        p.nft = ipcaller;
        p.isIPForSale = _isIPforSale;
        p.ipPrice = _ipPrice;
        p.licensePrice = _licensePrice;

        emit AssetRegistered(ipcaller, _licensePrice, _ipPrice, _isIPforSale);
    }

    /**
     * See {IAssetMarket}
     */
    function updateAsset(
        uint256 _licensePrice,
        bool _isIPforSale,
        uint256 _ipPrice
    ) external {
        // msg.sender/ipcaller should be the IP/nft contract
        address ipcaller = msg.sender;
        require(ipcaller != address(0), "Market: bad address");

        Product storage p = products[ipcaller];
        require(p.nft != address(0), "Market: product doesn't exist");
        require(p.nft == ipcaller, "Market: not the product owner");

        p.isIPForSale = _isIPforSale;
        p.ipPrice = _ipPrice;
        p.licensePrice = _licensePrice;

        emit AssetUpdated(ipcaller, _licensePrice, _ipPrice, _isIPforSale);
    }

    /**
     * See {IAssetMarket}
     */
    function buyAsset(address _asset) external nonReentrant {
        require(_asset != address(0), "Market: bad Asset address");
        address buyer = msg.sender;

        Product memory p = products[_asset];
        require(_asset == p.nft, "Market: product not found");
        require(p.isIPForSale, "Market: Asset is not for sale");
        require(
            biotoken.balanceOf(buyer) >= p.ipPrice,
            "Market: insufficient biotokens"
        );

        BioAsset ba = BioAsset(p.nft);
        address realOwner = ba.owner();
        uint256 remainingLicenses = ba.availableLicenses();

        // xfer the payment to the original owner
        // Note: this assumes the buyer has authorized this contract
        // as an 'operator' to do xfers on their behalf
        biotoken.safeTransferFrom(buyer, realOwner, p.ipPrice);

        // 1: xfer remainder of licenses from the current owner to the IP buyer
        if (remainingLicenses > 0) {
            ba.safeTransferFrom(
                realOwner,
                buyer,
                ba.LICENSE(),
                remainingLicenses,
                ""
            );
        }

        // 2. then xfer the IP to the buyer
        ba.safeTransferFrom(realOwner, buyer, ba.IP(), 1, "");
    }

    /**
     * See {IAssetMarket}
     */
    function buyLicense(address _asset, uint256 _qty) external nonReentrant {
        require(_asset != address(0), "Market: bad Asset address");
        address buyer = msg.sender;

        Product memory p = products[_asset];
        require(_asset == p.nft, "Market: product not found");
        uint256 cost = p.licensePrice * _qty;

        BioAsset ba = BioAsset(p.nft);
        require(
            ba.availableLicenses() >= _qty,
            "Market: not enough licenses available"
        );
        address realOwner = ba.owner();

        require(
            biotoken.balanceOf(buyer) >= cost,
            "Market: insufficient biotokens"
        );

        // xfer the payment to the owner
        // Note: this assumes the buyer has authorized this contract
        // as an 'operator' to do xfers on their behalf
        biotoken.safeTransferFrom(buyer, realOwner, cost);

        // xfer the license to the buyer
        ba.safeTransferFrom(realOwner, buyer, ba.LICENSE(), _qty, "");
    }

    /**
     * @dev get a specific Asset by it's address
     */
    function getProduct(address _asset)
        external
        view
        returns (
            uint256 licensePrice,
            bool ipForSale,
            uint256 ipPrice
        )
    {
        licensePrice = products[_asset].licensePrice;
        ipForSale = products[_asset].isIPForSale;
        ipPrice = products[_asset].ipPrice;
    }
}
