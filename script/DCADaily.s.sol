// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {DCADaily} from "../src/DCADaily.sol";

contract CounterScript is Script {
    address public dai = 0x869fc98Ae10E33a59443715F852A54ee7499a939; // Sepolia Dai

    function setUp() public {}

    function run() public {
        vm.broadcast();
        new DCADaily(dai);
    }
}
