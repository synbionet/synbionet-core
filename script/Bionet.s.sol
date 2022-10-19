// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: Copyright MITRE Corporation
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

// use this later to deploy stuff
contract BionetScript is Script {
    function setUp() public {}

    function run() public view {
        console2.log("~~~ deploy... ~~~");
        //vm.broadcast();
    }
}
