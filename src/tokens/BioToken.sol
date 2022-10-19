// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation

pragma solidity ^0.8.16;

import "openzepplin/token/ERC20/ERC20.sol";
import "openzepplin/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BioToken Utility Token for the Bionet
 *
 * @notice Utility token used by the Bionet. Exchange Ether for
 * tokens using a simple fixed rate to determine the exchange cost.
 * The BioToken reserve expands and contracts based on demand.
 *
 * NOTE: This is to be used for experimentation only
 */
contract BioToken is ERC20 {
    // rate of exchange: 1 token costs 0.001 eth
    uint256 immutable RATE = 1e15;

    constructor() ERC20("biotoken", "BT") {}

    /**
     * @notice Buy tokens with Ether.  Each purchase
     * increases the overall supply of tokens.
     * @param _amt the number of tokens to purchase
     */
    function buy(uint256 _amt) public payable {
        uint256 cost = calculateCost(_amt);

        require(msg.value >= cost, "BioToken: insufficient ether");

        // give the user their tokens
        _mint(msg.sender, _amt);

        // send back any change from overpayment
        uint256 change = msg.value - cost;
        if (change >= 1) payable(msg.sender).transfer(change);
    }

    /**
     * @notice Withdraw biotokens for Ether.  Selling
     * decreases the overall supply of tokens.
     * @param _numberOfTokens the amount of tokens to sell.
     */
    function withdraw(uint256 _numberOfTokens) public {
        require(
            this.balanceOf(msg.sender) >= _numberOfTokens,
            "BioToken: not enough tokens to sell"
        );

        uint256 cost = calculateCost(_numberOfTokens);

        require(
            address(this).balance >= cost,
            "BioToken: not enough ether to withdraw"
        );

        // Burn the tokens being sold
        _burn(msg.sender, _numberOfTokens);

        // Send the seller their Ether
        // TODO: maybe use a withdraw pattern in the future?
        payable(msg.sender).transfer(cost);
    }

    /**
     * @dev Calculate the cost of tokens in wei
     * @param _numOfTokens the number of tokens
     * @return amount in wei
     */
    function calculateCost(uint256 _numOfTokens) public pure returns (uint256) {
        return _numOfTokens * RATE;
    }
}
