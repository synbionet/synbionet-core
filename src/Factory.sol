// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.16;

import "./tokens/IntellectualProperty.sol";

/**
 * @notice Create an IP token.  Should be called
 * by the IP owner - for now, they bear the expense (skin in the game)
 */
contract Factory {
    // pointer to deployed market
    address immutable market;

    /**
     * @notice Create a factory (once)
     * @param _market address deployed market
     */
    constructor(address _market) {
        market = _market;
    }

    /**
     * @notice Create and deploy an IP contract.
     * The caller of *this* function is the owner of the IP.
     * @param _uri the URL to metadata
     * @return _ the address of new token
     */
    function createIP(string calldata _uri) public returns (address) {
        require(msg.sender != address(0), "Factory: invalid sender address");

        // Keep it simple for now...
        // TODO: May use predictable addresses based on uri in the future...
        // remember the IP address is it's identifier in the market
        IntellectualProperty ip = new IntellectualProperty(
            msg.sender,
            _uri,
            market
        );

        return address(ip);
    }
}
