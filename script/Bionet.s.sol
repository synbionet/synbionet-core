// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/tokens/BioToken.sol";
import "../src/NoFeeMarket.sol";
import "../src/Factory.sol";
import "../src/tokens/BioAsset.sol";

// use this later to deploy stuff
contract BionetScript is Script {
    function setUp() public {}

    function run() public {
        console2.log("~~~ deploy... ~~~");
        // for local testing, anvil account 0 private key
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerPrivateKey);

        BioToken bioToken = new BioToken();
        NoFeeMarket market = new NoFeeMarket(address(bioToken));
        Factory factory = new Factory(address(market));
        address ip_address = factory.createAsset("http://hello.there");

        BioAsset ip = BioAsset(ip_address);
        console.log(ip.uri(1));
        ip.registerWithMarket({
            _licensePrice: 2,
            _licenseQty: 10,
            _isIPForSale: true,
            _ipPrice: 5
        });

        console2.log("market address");
        console2.log(address(market));
        console2.log("factory address");
        console2.log(address(factory));
        console2.log("biotoken address");
        console2.log(address(bioToken));
        console2.log("bioasset address");
        console2.log(address(ip));
        vm.stopBroadcast();
    }
}
