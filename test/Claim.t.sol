// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5.4.0/token/ERC20/IERC20.sol";

import { IVestingVault } from "../src/interfaces/IVestingVault.sol";

import { VestingVaultFixture } from "./utils/VestingVaultFixture.sol";

contract ClaimTest is VestingVaultFixture {
    function test_claim() public {
        vault.addGrant(USER, 100 ether, 1 days, 11 days);

        skip(2 days);
        uint128 vestedBefore = vault.vestedOf(USER);

        vm.expectEmit();
        emit IERC20.Transfer(address(vault), USER, 10 ether);
        vm.expectEmit();
        emit IVestingVault.Claimed(USER, 10 ether);
        vm.prank(USER);
        vault.claim();

        assertEq(vault.getGrant(USER).claimed, 10 ether, "Invalid claimed");
        assertEq(token.balanceOf(USER), 10 ether, "Invalid user balance");
        assertEq(token.balanceOf(address(vault)), 90 ether, "Invalid vault balance");
        assertEq(token.balanceOf(address(vault)), 90 ether, "Invalid vault balance");
        assertEq(vestedBefore, 10 ether, "Invalid vested after claim");
        assertEq(vault.vestedOf(USER), 0, "Invalid vested after claim");
    }

    /* -------------------------------------------------------------------------- */
    /*                                   REVERTS                                  */
    /* -------------------------------------------------------------------------- */

    function test_revertWhen_claimNotGranted() public {
        vm.prank(USER);
        vm.expectRevert(IVestingVault.NotGranted.selector);
        vault.claim();
    }

    function test_revertWhen_claimCliffNotReached() public {
        vault.addGrant(USER, 100 ether, 1 days, 11 days);

        skip(12 hours);
        assertEq(vault.vestedOf(USER), 0, "Invalid vested");

        vm.prank(USER);
        vm.expectRevert(IVestingVault.CliffNotReached.selector);
        vault.claim();
    }

    function test_revertWhen_claimNoClaim() public {
        vault.addGrant(USER, 100 ether, 1 days, 11 days);

        skip(1 days);

        vm.prank(USER);
        vm.expectRevert(IVestingVault.NoClaim.selector);
        vault.claim();
    }
}
