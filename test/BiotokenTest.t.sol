// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import "../src/tokens/BioToken.sol";

contract BioTokenTest is Test {
    BioToken public token;

    function setUp() public {
        token = new BioToken();
    }

    function testNotEnoughMoney() public {
        vm.deal(address(this), 0.003 ether);
        vm.expectRevert("BioToken: insufficient ether");
        token.buy{value: 0.002 ether}(3);
    }

    function testNotEnoughTokensToSell() public {
        vm.deal(address(this), 1 ether);
        token.buy{value: 0.002 ether}(1);
        vm.expectRevert("BioToken: not enough tokens to sell");
        token.withdraw(2);
    }

    function testBuySell() public {
        /// simplify the account balance
        vm.deal(address(this), 1 ether);
        /// Buy
        token.buy{value: 0.002 ether}(1);

        /// now there's 1 token
        assertEq(token.totalSupply(), 1);
        /// ... and I happen to own it
        assertEq(token.balanceOf(address(this)), 1);

        /// the eth balance of tokens is ...
        assertEq(address(token).balance, 0.001 ether);
        /// my balance is ....
        assertEq(address(this).balance, 0.999 ether);

        /// Now sell them back
        token.withdraw(1);
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(address(this)), 0);

        assertEq(address(token).balance, 0 ether);
        assertEq(address(this).balance, 1 ether);
    }

    // Here to receive refunds from overpayments... (change back)
    receive() external payable {}
}
