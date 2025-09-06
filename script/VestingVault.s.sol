// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Script } from "forge-std-1.10.0/Script.sol";
import { IERC20 } from "@openzeppelin-contracts-5.4.0/token/ERC20/IERC20.sol";

import { VestingVault } from "../src/VestingVault.sol";

contract VestingVaultScript is Script {
    IERC20 constant TOKEN = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH

    function run() public returns (VestingVault) {
        vm.startBroadcast();
        VestingVault vault = new VestingVault(TOKEN, msg.sender);
        vm.stopBroadcast();
        return vault;
    }
}
