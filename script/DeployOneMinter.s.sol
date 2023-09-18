// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {OneMinter} from "../src/OneMinter.sol";

contract DeployOneMinter is Script {
    address DEPLOYER = makeAddr("deployer");

    function run() external returns (OneMinter) {
        vm.startBroadcast(DEPLOYER);
        OneMinter oneMinter = new OneMinter();
        vm.stopBroadcast();
        return oneMinter;
    }
}
