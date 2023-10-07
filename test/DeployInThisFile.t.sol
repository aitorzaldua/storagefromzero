// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeployInThisFile is Test {
    SimpleStorage simpleStorage;

    function setUp() external {
        simpleStorage = new SimpleStorage();
    }

    function testCheckAddresses() external view {
        console.log("deployed contract:              ", address(simpleStorage));
        console.log("owner of the deployed contract: ", simpleStorage.owner());
        console.log("address of the test contract:   ", address(this));
    }
}
