// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {OneMinter} from "../src/OneMinter.sol";
import {DeployOneMinter} from "../script/DeployOneMinter.s.sol";

contract OneMinterTest is Test {
    OneMinter oneMinter;
    /////////////
    // USERS ////
    /////////////

    address DEPLOYER = makeAddr("deployer");
    address USER1 = makeAddr("user1");

    function setUp() external {
        DeployOneMinter deployOneMinter = new DeployOneMinter();
        oneMinter = deployOneMinter.run();
    }

    function testOMLogs() external view {
        console.log("address this:           ", address(this));
        console.log("contract OneMinter:     ", address(oneMinter));
        console.log("OneMinter deployer:     ", oneMinter.owner());
        console.log("address DEPLOYER:       ", DEPLOYER);
        console.log("address USER1:          ", USER1);
    }
}
