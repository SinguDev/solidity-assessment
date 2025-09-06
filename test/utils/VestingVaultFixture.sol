// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std-1.10.0/Test.sol";

import { VestingVault } from "../../src/VestingVault.sol";

import { ERC20Mock } from "../utils/ERC20Mock.sol";

contract VestingVaultFixture is Test {
    VestingVault internal vault;
    ERC20Mock internal token;
    address internal constant USER = address(1);

    function setUp() public virtual {
        token = new ERC20Mock();
        vault = new VestingVault(token, address(this));
        token.mint(address(this), 1_000_000 ether);
        vault.getToken().approve(address(vault), type(uint256).max);
    }
}
