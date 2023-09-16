// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {OneMinter} from "../src/OneMinter.sol";

contract OneMinterTest is Test {
    OneMinter oneMinter;

    /////////////
    // USERS ////
    /////////////

    address DEPLOYER = makeAddr("deployer");
    address USER1 = makeAddr("user1");

    function setUp() external {
        vm.prank(DEPLOYER);
        oneMinter = new OneMinter();
    }

    function testLogs() external view {
        console.log("address this:           ", address(this));
        console.log("contract SimpleStorage: ", address(oneMinter));
        console.log("SimpleStorage deployer: ", oneMinter.owner());
        console.log("address DEPLOYER:       ", DEPLOYER);
        console.log("address USER1:          ", USER1);
    }
}
