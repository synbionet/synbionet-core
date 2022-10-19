// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation

pragma solidity ^0.8.16;

import "openzepplin/token/ERC20/IERC20.sol";
import "openzepplin/token/ERC1155/IERC1155.sol";
import "openzepplin/security/ReentrancyGuard.sol";
import "openzepplin/token/ERC20/utils/SafeERC20.sol";
import "openzepplin/utils/introspection/ERC165Checker.sol";

import "./tokens/BioToken.sol";
import "./tokens/IntellectualProperty.sol";
import "./IMarket.sol";

/**
 * @title Market for Intelletual Property and Licenses
 * @notice Manages the exchange of Biotokens for IP/License tokens.
 * There is no owner of this contract.  It simply functions as a proxy
 * for IP contracts.
 *
 * This version defines a simple exchange protocol.
 *
 * Note: Both buyers and sellers must approve the market to make transfers on their behalf.
 * The market facilitates the exchange.
 *
 * TODO:
 *  - collect network fees
 *  - royalties integration
 */
contract Market is IMarket, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // access to the biotoken
    IERC20 immutable biotoken;

    // storage of IP addresses to 'product' information
    mapping(address => Product) private products;

    // keep a list of productIds (IP addresses). Mainly for UI stuff
    address[] private productIds;

    event NewProduct(
        address indexed id,
        uint256 licensePrice,
        bool ipForSale,
        uint256 ipPrice
    );

    event UpdatedProduct(
        address indexed id,
        uint256 licensePrice,
        bool ipForSale,
        uint256 ipPrice
    );

    // container for IP product information
    struct Product {
        address nft;
        bool isIPForSale;
        uint256 licensePrice; // in Eth for a given license
        uint256 ipPrice; // in Eth IF ipForSale is true
    }

    /**
     * @notice Create the market (once).  See Factory.sol
     * @param _biotoken address of the deployed biotoken contract
     */
    constructor(address _biotoken) {
        biotoken = IERC20(_biotoken);
    }

    /**
     * @notice Register a product (IP) with the market.  Can only be done
     * once per unique IP. This is called from IntellectualProperty contract.
     * @param _licensePrice price of a license in biotokens
     * @param _isIPForSale is the IP for sale
     * @param _ipPrice the price in biotokens for the IP (if for sale)
     *
     * Will revert IF:
     * - the caller is the zero address
     * - the calling address is NOT an IP contract
     * - the product has already been registered
     */
    function registerProduct(
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external {
        // msg.sender/ipcaller should be the IP/nft contract
        address ipcaller = msg.sender;
        require(ipcaller != address(0), "Market: bad address");
        require(_isIPContract(ipcaller), "Market: not an IP contract");

        Product storage p = products[ipcaller];
        require(p.nft == address(0), "Market: product already exists");

        p.nft = ipcaller;
        p.isIPForSale = _isIPForSale;
        p.ipPrice = _ipPrice;
        p.licensePrice = _licensePrice;
        productIds.push(ipcaller);

        emit NewProduct(ipcaller, _licensePrice, _isIPForSale, _ipPrice);
    }

    /**
     * @notice Update an existing product
     * @param _licensePrice price of a license in biotokens
     * @param _isIPForSale is the IP for sale
     * @param _ipPrice the price in biotokens for the IP (if for sale)
     *
     * Will revert IF:
     * - the caller is the zero address
     * - the product doesn't exist
     * - the caller is NOT the product owner
     */
    function updateProduct(
        uint256 _licensePrice,
        bool _isIPForSale,
        uint256 _ipPrice
    ) external {
        // msg.sender/ipcaller should be the IP/nft contract
        address ipcaller = msg.sender;
        require(ipcaller != address(0), "Market: bad address");

        Product storage p = products[ipcaller];
        require(p.nft != address(0), "Market: product doesn't exist");
        require(p.nft == ipcaller, "Market: not the product owner");

        p.isIPForSale = _isIPForSale;
        p.ipPrice = _ipPrice;
        p.licensePrice = _licensePrice;

        // Emit update
        emit UpdatedProduct(ipcaller, _licensePrice, _isIPForSale, _ipPrice);
    }

    // TODO: remove a product for sale
    function removeProductFromMarket() external {
        // msg.sender should be the nft contract
    }

    /**
     * @notice Called by buyers of IP.
     * @param _nft the address of the IP to buy
     *
     * Will revert IF:
     * - the caller is the zero address
     * - the product doesn't exist
     * - the IP is NOT for sale
     * - the _nft address is NOT an IP contract
     * - the buyer does NOT have enough biotokens for the price
     * - the biotoken xfer fails
     */
    function buyIP(address _nft) external nonReentrant {
        // NOTE: we protect against reentry here as we're
        // violating the check/effects/interaction pattern.
        // probably overly-cautious...

        require(_nft != address(0), "Market: bad IP address");

        Product memory p = products[_nft];
        require(_nft == p.nft, "Market: product not found");
        // TODO: require p.open...
        require(p.isIPForSale, "Market: IP is not for sale");

        IntellectualProperty ip = IntellectualProperty(p.nft);

        address buyer = msg.sender;
        address realOwner = ip.owner();
        uint256 remainingLicenses = ip.availableLicenses();

        // TODO: Calculate network fee here...

        require(
            biotoken.balanceOf(buyer) >= p.ipPrice,
            "Market: insufficient biotokens"
        );

        // xfer the payment to the original IP owner
        // Note: this assumes the buyer has authorized this contract
        // as an 'operator' to do xfers on their behalf
        biotoken.safeTransferFrom(buyer, realOwner, p.ipPrice);

        // 1: xfer remainder of licenses from the current owner to the IP buyer
        if (remainingLicenses > 0) {
            ip.safeTransferFrom(
                realOwner,
                buyer,
                ip.LICENSE(),
                remainingLicenses,
                ""
            );
        }

        // 2. then xfer the IP to the buyer
        ip.safeTransferFrom(realOwner, buyer, ip.IP(), 1, "");
    }

    /**
     * @notice Called by buyers of _qty of licenses
     * @param _nft the address of the IP to buy
     * @param _qty is the number of licenses they wish to purchase
     *
     * Will revert IF:
     * - the caller is the zero address
     * - the product doesn't exist
     * - the _nft address is NOT an IP contract
     * - there are NOT enough license for the requested _qty
     * - the buyer doesn't have enough biotokens for the purchase
     * - the biotoken xfer fails
     */
    function buyLicense(address _nft, uint256 _qty) external nonReentrant {
        // NOTE: we protect against reentry here as we're
        // violating the check/effects/interaction pattern.
        // probably overly-cautious...

        require(_nft != address(0), "Market: bad IP address");

        Product memory p = products[_nft];
        require(_nft == p.nft, "Market: product not found");

        IntellectualProperty ip = IntellectualProperty(p.nft);

        require(
            ip.availableLicenses() >= _qty,
            "Market: not enough licenses available"
        );

        uint256 cost = p.licensePrice * _qty;
        address buyer = msg.sender;
        address realOwner = ip.owner();

        // TODO: Calculate network fee here...
        // TODO: Handle 'free' stuff (no cost)

        require(
            biotoken.balanceOf(buyer) >= cost,
            "Market: insufficient biotokens"
        );

        // xfer the payment to the IP owner
        // Note: this assumes the buyer has authorized this contract
        // as an 'operator' to do xfers on their behalf
        biotoken.safeTransferFrom(buyer, realOwner, cost);

        // xfer the license to the buyer
        ip.safeTransferFrom(realOwner, buyer, ip.LICENSE(), _qty, "");
    }

    // Views //

    /**
     * @notice Returns the number of registered products
     * @return _ number of products
     */
    function numberOfProducts() external view returns (uint256) {
        return productIds.length;
    }

    /**
     * @notice return a list of product IDs (addresses)
     */
    function getProducts() external view returns (address[] memory) {
        return productIds;
    }

    /**
     * @notice get a specific product
     */
    function getProduct(address _productId)
        external
        view
        returns (
            uint256 licensePrice,
            bool ipForSale,
            uint256 ipPrice
        )
    {
        licensePrice = products[_productId].licensePrice;
        ipForSale = products[_productId].isIPForSale;
        ipPrice = products[_productId].ipPrice;
    }

    /**
     * Use to check if the calling address is an instance of ERC1155
     */
    function _isIPContract(address _account) internal view returns (bool) {
        return
            ERC165Checker.supportsInterface(
                _account,
                type(IERC1155).interfaceId
            );
    }
}
