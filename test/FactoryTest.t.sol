// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "openzepplin/token/ERC1155/utils/ERC1155Holder.sol";

import "../src/Factory.sol";
import "../src/tokens/IntellectualProperty.sol";
import "../src/tokens/BioToken.sol";
import "../src/Market.sol";

contract FactoryTest is Test, ERC1155Holder {
    Factory public factory;

    function setUp() public {
        BioToken biotoken = new BioToken();
        Market m = new Market(address(biotoken));
        factory = new Factory(address(m));
    }

    /// Make sure the basics work
    function testCreateIp() public {
        address ip_address = factory.createIP("http://hello.there");
        assertTrue(ip_address != address(0));
        IntellectualProperty ip = IntellectualProperty(ip_address);

        assertEq("http://hello.there", ip.uri(1));

        // ID doesn't matters
        assertEq("http://hello.there", ip.uri(25));
        assertEq(address(this), ip.owner());
    }

    function testMustHaveNonZeroAddress() public {
        // change msg.sender to zero-address
        vm.prank(address(0));
        vm.expectRevert("Factory: invalid sender address");
        factory.createIP("http://hello.there");
    }
}
