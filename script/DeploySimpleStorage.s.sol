// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    address deployer = makeAddr("deployer");
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");

    address public banana = deployer;

    function run() external returns (SimpleStorage) {
        vm.startBroadcast(deployer);
        SimpleStorage simpleStorage = new SimpleStorage();
        vm.stopBroadcast();
        return simpleStorage;
    }
}
