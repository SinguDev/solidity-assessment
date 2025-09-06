// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin-contracts-5.4.0/token/ERC20/IERC20.sol";

interface IVestingVault {
    /* -------------------------------------------------------------------------- */
    /*                                   STRUCT                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Struct representing a token vesting grant.
    /// @param total The total number of tokens granted to the recipient.
    /// @param claimed The number of tokens already claimed by the recipient.
    /// @param start The timestamp when vesting begins.
    /// @param cliff The duration in seconds before vesting starts (cliff period).
    /// @param duration The total vesting duration in seconds from the start.
    struct Grant {
        uint128 total;
        uint128 claimed;
        uint64 start;
        uint64 cliff;
        uint64 duration;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Error indicating that the provided beneficiary address is invalid.
    error InvalidBeneficiary();

    /// @notice Error indicating that the provided amount is invalid (e.g., zero).
    error InvalidAmount();

    /// @notice Error indicating that the provided duration is invalid (e.g., zero or too short).
    error InvalidDuration();

    /// @notice Error indicating that tokens have already been granted to the beneficiary.
    error AlreadyGranted();

    /// @notice Error indicating that no grant exists for the beneficiary.
    error NotGranted();

    /// @notice Error indicating that the cliff period has not yet been reached.
    error CliffNotReached();

    /// @notice Error indicating that the vesting period has not yet ended.
    error VestingNotEnded();

    /// @notice Error indicating that there are no tokens to claim.
    error NoClaim();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Emitted when a new grant is added for a beneficiary.
    /// @param beneficiary The address receiving the grant.
    /// @param amount The amount of tokens granted.
    /// @param cliffSeconds The cliff duration in seconds before vesting starts.
    /// @param durationSeconds The total vesting duration in seconds.
    event GrantAdded(
        address indexed beneficiary, uint128 amount, uint64 cliffSeconds, uint64 durationSeconds
    );

    /// @notice Emitted when a grant is removed for a beneficiary.
    /// @param beneficiary The address of the beneficiary whose grant is removed.
    /// @param amount The amount of tokens removed from the grant.
    event GrantRemoved(address indexed beneficiary, uint128 amount);

    /// @notice Emitted when a beneficiary claims vested tokens.
    /// @param beneficiary The address of the beneficiary claiming tokens.
    /// @param amount The amount of tokens claimed.
    event Claimed(address indexed beneficiary, uint128 amount);

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns the minimum duration required for a claim period
    /// @return The minimum claim duration in seconds
    function MIN_CLAIM_DURATION() external pure returns (uint256);

    /// @notice Returns the additional duration allowed for claims
    /// @return The extra claim duration in seconds
    function EXTRA_CLAIM_DURATION() external pure returns (uint256);

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC / EXTERNAL                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Allows a user to claim their vested tokens.
    function claim() external;

    /// @notice Returns the amount of tokens vested for a specific user.
    /// @param user The address of the user.
    /// @return The amount of vested tokens for the user.
    function vestedOf(address user) external view returns (uint128);

    /// @notice Retrieves the token associated with this contract.
    /// @return The ERC20 token used in this contract.
    function getToken() external view returns (IERC20);

    /// @notice Retrieves the grant details for a specific user.
    /// @param user The address of the user.
    /// @return The Grant struct containing vesting details for the user.
    function getGrant(address user) external view returns (Grant memory);

    /* -------------------------------------------------------------------------- */
    /*                                    ADMIN                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Creates a new vesting grant for a beneficiary
    /// @param beneficiary The address of the recipient of the grant
    /// @param amount The total amount of tokens to vest
    /// @param cliffSeconds The duration in seconds before vesting begins
    /// @param durationSeconds The total duration in seconds over which tokens vest
    function addGrant(
        address beneficiary,
        uint128 amount,
        uint64 cliffSeconds,
        uint64 durationSeconds
    ) external;

    /// @notice Removes an existing vesting grant for a beneficiary
    /// @param beneficiary The address of the beneficiary whose grant will be removed
    function removeGrant(address beneficiary) external;
}
