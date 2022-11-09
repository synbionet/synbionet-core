// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.16;

import "./tokens/BioAsset.sol";

/**
 * @dev Create an Asset contract.  Should be called by the Asset owner.
 * For now, they bear the deployment expense, may change
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
     * @dev Create and deploy an Asset contract.
     * The caller of *this* function is the owner.
     * @param _uri the URL to metadata
     * @return _ the address of new token
     */
    function createAsset(string calldata _uri) public returns (address) {
        require(msg.sender != address(0), "Factory: invalid sender address");

        // Keep it simple for now...
        // TODO: CREATE/CREATE2
        BioAsset asset = new BioAsset(msg.sender, _uri, market);

        return address(asset);
    }
}
