// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ReentrancyGuardTransient } from
    "@openzeppelin-contracts-5.4.0/utils/ReentrancyGuardTransient.sol";
import { Ownable2Step } from "@openzeppelin-contracts-5.4.0/access/Ownable2Step.sol";
import { Ownable } from "@openzeppelin-contracts-5.4.0/access/Ownable.sol";
import { IERC20 } from "@openzeppelin-contracts-5.4.0/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solady-0.1.26/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solady-0.1.26/utils/FixedPointMathLib.sol";

import { IVestingVault } from "./interfaces/IVestingVault.sol";

contract VestingVault is IVestingVault, Ownable2Step, ReentrancyGuardTransient {
    using SafeTransferLib for address;

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IVestingVault
    uint256 public constant MIN_CLAIM_DURATION = 1 days;

    /// @inheritdoc IVestingVault
    uint256 public constant EXTRA_CLAIM_DURATION = 1 days;

    /* -------------------------------------------------------------------------- */
    /*                                  VARIABLES                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev The ERC20 token used for the vesting or grant process.
    IERC20 internal immutable _token;

    /// @dev Mapping from beneficiary addresses to their respective grant details.
    mapping(address => Grant) internal _grants;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Initializes the contract with the specified token and owner
    /// @param token The ERC20 token that is mintable and used in the contract
    /// @param owner The address of the owner who will have administrative privileges
    constructor(IERC20 token, address owner) Ownable(owner) {
        _token = token;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC / EXTERNAL                             */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IVestingVault
    function claim() external {
        Grant memory grant = _grants[msg.sender];

        require(grant.total > 0, NotGranted());
        require(block.timestamp >= grant.start + grant.cliff, CliffNotReached());

        uint128 claimableAmount = vestedOf(msg.sender);
        require(claimableAmount > 0, NoClaim());

        _grants[msg.sender].claimed += claimableAmount;
        address(_token).safeTransfer(msg.sender, claimableAmount);

        emit Claimed(msg.sender, claimableAmount);
    }

    /// @inheritdoc IVestingVault
    function vestedOf(address user) public view returns (uint128) {
        Grant memory grant = _grants[user];

        // If no grant or cliff not reached, nothing is vested
        if (grant.total == 0 || block.timestamp < grant.start + grant.cliff) {
            return 0;
        }

        // If the vesting duration has fully elapsed, all tokens are vested
        if (block.timestamp >= grant.start + grant.duration) {
            return grant.total - grant.claimed;
        }

        uint128 vested = uint128(
            FixedPointMathLib.fullMulDiv(
                grant.total,
                block.timestamp - (grant.start + grant.cliff),
                grant.duration - grant.cliff
            )
        );

        return vested - grant.claimed;
    }

    /// @inheritdoc IVestingVault
    function getToken() external view returns (IERC20) {
        return _token;
    }

    /// @inheritdoc IVestingVault
    function getGrant(address user) external view returns (Grant memory) {
        return _grants[user];
    }

    /* -------------------------------------------------------------------------- */
    /*                                    ADMIN                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IVestingVault
    function addGrant(
        address beneficiary,
        uint128 amount,
        uint64 cliffSeconds,
        uint64 durationSeconds
    ) external onlyOwner {
        require(beneficiary != address(0), InvalidBeneficiary());
        require(amount > 0, InvalidAmount());
        require(cliffSeconds + MIN_CLAIM_DURATION <= durationSeconds, InvalidDuration());
        require(_grants[beneficiary].total == 0, AlreadyGranted());

        _grants[beneficiary] = Grant({
            total: amount,
            claimed: 0,
            start: uint64(block.timestamp),
            cliff: cliffSeconds,
            duration: durationSeconds
        });

        // Transfer the tokens from the owner to the contract
        address(_token).safeTransferFrom(msg.sender, address(this), amount);

        emit GrantAdded(beneficiary, amount, cliffSeconds, durationSeconds);
    }

    /// @inheritdoc IVestingVault
    function removeGrant(address beneficiary) external onlyOwner {
        require(beneficiary != address(0), InvalidBeneficiary());

        Grant memory grant = _grants[beneficiary];

        require(grant.total > 0, NotGranted());
        require(
            block.timestamp >= grant.start + grant.duration + EXTRA_CLAIM_DURATION,
            VestingNotEnded()
        );

        // Remove the grant before transferring tokens to prevent reentrancy issues
        delete _grants[beneficiary];

        uint128 unclaimed;

        // If there are unclaimed tokens, transfer them back to the owner
        if (grant.total > grant.claimed) {
            unclaimed = grant.total - grant.claimed;
            address(_token).safeTransfer(msg.sender, unclaimed);
        }

        emit GrantRemoved(beneficiary, unclaimed);
    }
}
