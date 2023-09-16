// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {DeploySimpleStorage} from "../script/DeploySimpleStorage.s.sol";

contract StakeContractTest is Test {
    SimpleStorage simpleStorage;

    /////////////
    // USERS ////
    /////////////

    address DEPLOYER = makeAddr("deployer");
    address USER1 = makeAddr("user1");

    function setUp() external {
        DeploySimpleStorage deploySimpleStorage = new DeploySimpleStorage();
        simpleStorage = deploySimpleStorage.run();
    }

    function testSSLogs() external view {
        console.log("address this:           ", address(this));
        console.log("contract SimpleStorage: ", address(simpleStorage));
        console.log("SimpleStorage deployer: ", simpleStorage.owner());
        console.log("address DEPLOYER:       ", DEPLOYER);
        console.log("address USER1:          ", USER1);
    }
}
