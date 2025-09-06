// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin-contracts-5.4.0/access/Ownable.sol";

import { IVestingVault } from "../src/interfaces/IVestingVault.sol";

import { VestingVaultFixture } from "./utils/VestingVaultFixture.sol";

contract RemoveGrantTest is VestingVaultFixture {
    function test_removeGrant() public {
        vault.addGrant(USER, 100 ether, 1 days, 11 days);

        skip(11 days + vault.EXTRA_CLAIM_DURATION());
        uint128 vestedBefore = vault.vestedOf(USER);

        vm.expectEmit();
        emit IVestingVault.GrantRemoved(USER, 100 ether);
        vault.removeGrant(USER);

        IVestingVault.Grant memory grant = vault.getGrant(USER);
        assertEq(grant.total, 0, "Invalid total");
        assertEq(grant.claimed, 0, "Invalid claimed");
        assertEq(grant.start, 0, "Invalid start");
        assertEq(grant.cliff, 0, "Invalid cliff");
        assertEq(grant.duration, 0, "Invalid duration");
        assertEq(token.balanceOf(address(vault)), 0, "Invalid vault balance");
        assertEq(vestedBefore, 100 ether, "Invalid user balance");
    }

    /* -------------------------------------------------------------------------- */
    /*                                   REVERTS                                  */
    /* -------------------------------------------------------------------------- */

    function test_revertWhen_removeGrantNotOwner() public {
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        vault.removeGrant(USER);
    }

    function test_reverWhen_removeGrantInvalidBeneficiary() public {
        vm.expectRevert(IVestingVault.InvalidBeneficiary.selector);
        vault.removeGrant(address(0));
    }

    function test_revertWhen_removeGrantNotGranted() public {
        vm.expectRevert(IVestingVault.NotGranted.selector);
        vault.removeGrant(USER);
    }

    function test_revertWhen_removeGrantVestingNotEnded() public {
        vault.addGrant(USER, 100 ether, 1 days, 11 days);

        skip(11 days);
        vm.expectRevert(IVestingVault.VestingNotEnded.selector);
        vault.removeGrant(USER);
    }
}
