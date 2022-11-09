// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "openzepplin/token/ERC1155/utils/ERC1155Holder.sol";

import "../src/Factory.sol";

//import "../src/tokens/IntellectualProperty.sol";
//import "../src/Market.sol";

import "../src/tokens/BioAsset.sol";
import "../src/NoFeeMarket.sol";
import "../src/tokens/BioToken.sol";

contract MarketTest is Test, ERC1155Holder {
    NoFeeMarket market;
    Factory factory;
    BioToken biotoken;

    function setUp() public {
        biotoken = new BioToken();
        market = new NoFeeMarket(address(biotoken));
        factory = new Factory(address(market));
    }

    function testRegisterIP() public {
        // create actor
        address seller = address(0x1100);
        // fund wallet
        vm.deal(seller, 1 ether);

        vm.startPrank(seller);
        address ipforsale = factory.createAsset("http://x.one");
        BioAsset ip = BioAsset(ipforsale);

        ip.registerWithMarket({
            _licensePrice: 2,
            _licenseQty: 10,
            _isIPForSale: true,
            _ipPrice: 5
        });
        vm.stopPrank();

        // seller is the owner
        assertEq(seller, ip.owner());

        // Check number of licenses
        assertEq(10, ip.availableLicenses());

        (uint256 lp, bool fs, uint256 ipp) = market.getProduct(address(ip));
        assertEq(2, lp);
        assertTrue(fs);
        assertEq(5, ipp);
    }

    function testCantBuyAnythingNonIPAddress() public {
        vm.expectRevert("Market: product not found");
        market.buyAsset(address(this));

        vm.expectRevert("Market: product not found");
        market.buyLicense(address(this), 10);
    }

    function testNotEnoughToBuyIp() public {
        // create actors
        address seller = address(0x1100);
        address buyer = address(0x1120);

        // fund wallets
        vm.deal(seller, 1 ether);
        vm.deal(buyer, 1 ether);

        vm.startPrank(buyer);
        // buy 1 biotoken
        biotoken.buy{value: 0.05 ether}(1);
        // approve the market to act on my behalf
        // this means the market can exchange my biotokens
        // ... authorizing 1
        biotoken.approve(address(market), 1);
        vm.stopPrank();

        // Create IP and register for sale
        vm.startPrank(seller);
        address ipforsale = factory.createAsset("http://x.one");
        BioAsset ip = BioAsset(ipforsale);

        // Not IP price is 2 (not 1)
        ip.registerWithMarket({
            _licensePrice: 0,
            _licenseQty: 0,
            _isIPForSale: true,
            _ipPrice: 2
        }); // sell IP for 1 biotoken
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert("Market: insufficient biotokens");
        market.buyAsset(ipforsale);
        vm.stopPrank();
    }

    function testCreateAndSellIp() public {
        // create actors
        address seller = address(0x1100);
        address buyer = address(0x1120);

        // fund wallets
        vm.deal(seller, 1 ether);
        vm.deal(buyer, 1 ether);

        vm.startPrank(buyer);
        // buy 4 biotokens
        biotoken.buy{value: 0.05 ether}(4);
        // approve the market to act on my behalf
        // this means the market can exchange my biotokens
        // ... authorizing 1
        biotoken.approve(address(market), 1);
        vm.stopPrank();

        assertEq(1, biotoken.allowance(buyer, address(market)));

        // Create IP and register for sale
        vm.startPrank(seller);
        address ipforsale = factory.createAsset("http://x.one");
        BioAsset ip = BioAsset(ipforsale);

        ip.registerWithMarket({
            _licensePrice: 0,
            _licenseQty: 0,
            _isIPForSale: true,
            _ipPrice: 1
        }); // sell IP for 1 biotoken
        vm.stopPrank();

        assertEq(seller, ip.owner());

        // Buy the IP
        vm.startPrank(buyer);
        market.buyAsset(ipforsale);
        vm.stopPrank();

        // buyer balance is 1 less
        assertEq(3, biotoken.balanceOf(buyer));
        // seller balance is +1
        assertEq(1, biotoken.balanceOf(seller));
        // new owner
        assertEq(buyer, ip.owner());
    }

    function testCreateAndSellLicense() public {
        // create actors
        address seller = address(0x1100);
        address buyer = address(0x1120);

        // fund wallets
        vm.deal(seller, 1 ether);
        vm.deal(buyer, 1 ether);

        // Create Licenses and register for sale
        vm.startPrank(seller);
        address ipforsale = factory.createAsset("http://x.one");
        BioAsset ip = BioAsset(ipforsale);
        ip.registerWithMarket({
            _licensePrice: 1,
            _licenseQty: 5,
            _isIPForSale: false,
            _ipPrice: 0
        }); // sell license at 1 for 1 - total of 5
        vm.stopPrank();

        vm.startPrank(buyer);
        // buy 4 biotokens
        biotoken.buy{value: 0.05 ether}(4);
        // approve the market to act on my behalf
        // this means the market can exchange my biotokens
        // ... authorizing 1
        biotoken.approve(address(market), 4);
        vm.stopPrank();

        vm.startPrank(buyer);
        market.buyLicense(address(ip), 3);
        vm.stopPrank();

        assertEq(ip.balanceOf(buyer, ip.LICENSE()), 3);
        assertEq(ip.balanceOf(seller, ip.LICENSE()), 2);

        // buyer balance is 3 less
        assertEq(1, biotoken.balanceOf(buyer));
        // seller balance is +3
        assertEq(3, biotoken.balanceOf(seller));

        // Try to buy IP that's not for sale
        vm.expectRevert("Market: Asset is not for sale");
        market.buyAsset(address(ip));
    }

    function testProvenanceOfIP() public {
        // create actors
        address bob = address(0x1100);
        address alice = address(0x1120);
        address tom = address(0x1130);
        address dave = address(0x1140);
        address pat = address(0x1150);

        address[] memory actors = new address[](5);
        actors[0] = bob;
        actors[1] = alice;
        actors[2] = tom;
        actors[3] = dave;
        actors[4] = pat;

        // Every buys 5 biotokens
        assert(setupWalletFundsAndTokens(actors, 5));

        // Trail of sales
        // bob -> alice -> tom -> dave -> pat

        // Bob creates
        vm.startPrank(bob);
        address ipforsale = factory.createAsset("http://x.one");
        BioAsset ip = BioAsset(ipforsale);
        ip.registerWithMarket({
            _licensePrice: 1,
            _licenseQty: 5,
            _isIPForSale: true,
            _ipPrice: 1
        });
        vm.stopPrank();

        // alice buys
        vm.startPrank(alice);
        market.buyAsset(ipforsale);
        vm.stopPrank();
        assertEq(alice, ip.owner());

        // tom buys
        vm.startPrank(tom);
        market.buyAsset(ipforsale);
        vm.stopPrank();
        assertEq(tom, ip.owner());

        // dave buys
        vm.startPrank(dave);
        market.buyAsset(ipforsale);
        vm.stopPrank();
        assertEq(dave, ip.owner());

        // Dave ups the price to sell to patrick :-)
        vm.startPrank(dave);
        ip.updateWithMarket({
            _licensePrice: 1,
            _isIPForSale: true,
            _ipPrice: 2
        });
        vm.stopPrank();

        // pat buys
        vm.startPrank(pat);
        market.buyAsset(ipforsale);
        vm.stopPrank();
        assertEq(pat, ip.owner());

        // Check all biotoken balances from sales

        // up 1 from the initial sale
        assertEq(6, biotoken.balanceOf(bob));
        // paid 1 and then sold it back
        assertEq(5, biotoken.balanceOf(alice));
        // paid 1 and then sold it back
        assertEq(5, biotoken.balanceOf(tom));
        // paid 1 and then sold it back for 2
        assertEq(6, biotoken.balanceOf(dave));
        // spent 2
        assertEq(3, biotoken.balanceOf(pat));
    }

    function testSellLicensesAndIP() public {
        // create actors
        address bob = address(0x1100);
        address alice = address(0x1120);
        address tom = address(0x1130);
        address carl = address(0x1140);
        address[] memory actors = new address[](4);
        actors[0] = bob;
        actors[1] = alice;
        actors[2] = tom;
        actors[3] = carl;
        // Everyone buys 10 biotokens
        assert(setupWalletFundsAndTokens(actors, 10));

        // Bob creates IP with 10 licenses at a cost of 1 token each.
        // IP is for sale for 2 tokens
        vm.startPrank(bob);
        BioAsset ip = BioAsset(factory.createAsset("http://x.one"));
        ip.registerWithMarket({
            _licensePrice: 1,
            _licenseQty: 10,
            _isIPForSale: true,
            _ipPrice: 2
        });
        vm.stopPrank();

        // Sells 6 licenses to alice
        vm.startPrank(alice);
        market.buyLicense(address(ip), 6);
        vm.stopPrank();

        assertEq(6, ip.balanceOf(alice, ip.LICENSE()));
        assertEq(4, ip.balanceOf(bob, ip.LICENSE()));
        assertEq(16, biotoken.balanceOf(bob));
        assertEq(4, biotoken.balanceOf(alice));
        assertEq(ip.availableLicenses(), 4);

        // Sells IP to Tom
        vm.startPrank(tom);
        market.buyAsset(address(ip));
        vm.stopPrank();

        assertEq(tom, ip.owner());
        assertEq(18, biotoken.balanceOf(bob));
        assertEq(8, biotoken.balanceOf(tom));
        assertEq(ip.balanceOf(tom, ip.LICENSE()), 4);
        assertEq(ip.availableLicenses(), 4);

        // Tom sells licenses to carl
        vm.startPrank(carl);
        market.buyLicense(address(ip), 4);
        vm.stopPrank();

        assertEq(tom, ip.owner());
        assertEq(18, biotoken.balanceOf(bob));
        assertEq(12, biotoken.balanceOf(tom));
        assertEq(6, biotoken.balanceOf(carl));

        assertEq(ip.balanceOf(tom, ip.LICENSE()), 0);
        assertEq(ip.balanceOf(alice, ip.LICENSE()), 6);
        assertEq(ip.balanceOf(carl, ip.LICENSE()), 4);
        assertEq(ip.availableLicenses(), 0);

        // Carl tries to buy 1 more. But...
        vm.startPrank(carl);
        vm.expectRevert("Market: not enough licenses available");
        market.buyLicense(address(ip), 1);
        vm.stopPrank();
    }

    // lil helpers //

    // use to setup a list of actors and purchase biotokens
    function setupWalletFundsAndTokens(
        address[] memory actors,
        uint256 numOfBioTokens
    ) internal returns (bool) {
        for (uint256 i; i < actors.length; i++) {
            vm.deal(actors[i], 1 ether);

            vm.startPrank(actors[i]);
            // buy biotokens (TODO: fixed Ether amount is a problem here...)
            biotoken.buy{value: 0.06 ether}(numOfBioTokens);
            // approve the market to act on my behalf
            // this means the market can exchange my biotokens
            // ... authorizing 'numOfBioTokens'
            biotoken.approve(address(market), numOfBioTokens);
            vm.stopPrank();
        }

        return true;
    }
}
