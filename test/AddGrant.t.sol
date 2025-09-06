// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin-contracts-5.4.0/access/Ownable.sol";

import { IVestingVault } from "../src/interfaces/IVestingVault.sol";

import { VestingVaultFixture } from "./utils/VestingVaultFixture.sol";

contract AddGrantTest is VestingVaultFixture {
    function test_addGrant() public {
        vm.expectEmit();
        emit IVestingVault.GrantAdded(USER, 100 ether, 1 days, 11 days);
        vault.addGrant(USER, 100 ether, 1 days, 11 days);

        IVestingVault.Grant memory grant = vault.getGrant(USER);
        assertEq(grant.total, 100 ether, "Invalid total");
        assertEq(grant.claimed, 0, "Invalid claimed");
        assertEq(grant.start, uint64(block.timestamp), "Invalid start");
        assertEq(grant.cliff, 1 days, "Invalid cliff");
        assertEq(grant.duration, 11 days, "Invalid duration");
        assertEq(token.balanceOf(address(vault)), 100 ether, "Invalid vault balance");
    }

    /* -------------------------------------------------------------------------- */
    /*                                   REVERTS                                  */
    /* -------------------------------------------------------------------------- */

    function test_revertWhen_addGrantNotOwner() public {
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        vault.addGrant(USER, 100 ether, 1 days, 11 days);
    }

    function test_revertWhen_addGrantInvalidBeneficiary() public {
        vm.expectRevert(IVestingVault.InvalidBeneficiary.selector);
        vault.addGrant(address(0), 100 ether, 1 days, 11 days);
    }

    function test_revertWhen_addGrantZeroAmount() public {
        vm.expectRevert(IVestingVault.InvalidAmount.selector);
        vault.addGrant(USER, 0, 1 days, 11 days);
    }

    function test_revertWhen_addGrantInvalidDuration() public {
        vm.expectRevert(IVestingVault.InvalidDuration.selector);
        vault.addGrant(USER, 100 ether, 1 days, 0);
    }

    function test_revertWhen_addGrantAlreadyGranted() public {
        vault.addGrant(USER, 100 ether, 1 days, 11 days);

        vm.expectRevert(IVestingVault.AlreadyGranted.selector);
        vault.addGrant(USER, 100 ether, 1 days, 11 days);
    }
}
