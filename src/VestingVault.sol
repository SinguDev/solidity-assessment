// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IERC20Mintable {

    function transfer(address to, uint256 amt) external returns (bool);

}


contract VestingVault {

    error AlreadyEntrered();
    error NotOwner();

    uint256 public constant MIN_CLAIM_DURATION = 1 days;
    address public immutable OWNER;  
    uint8 private entered; 

    IERC20Mintable public immutable TOKEN;

    struct Grant {
        uint128 total;      // total tokens granted
        uint128 claimed;    // tokens already claimed
        uint64  start;      // vesting start timestamp
        uint64  cliff;      // cliff seconds after start
        uint64  duration;   // vesting duration in seconds
    }


    mapping(address => Grant) public grants;

    

    modifier onlyOwner() {
        require(msg.sender == OWNER, NotOwner());
        _;
    }

    modifier NonReentrant() {
        require(entered == 0, AlreadyEntrered());
        entered = 1;
        _;
        entered = 0;
    }


    constructor(IERC20Mintable _token, address owner) {
        OWNER = owner;
        TOKEN = _token;
    }


    function addGrant(
        address beneficiary,
        uint128 amount,
        uint64  cliffSeconds,
        uint64  durationSeconds
    ) external onlyOwner {
        require(beneficiary != address(0), "already granted");
        require(amount > 0, "already granted");
        require(cliffSeconds + MIN_CLAIM_DURATION <= durationSeconds, "already granted");

        grants[beneficiary] = Grant({
            total: amount,
            claimed: 0,
            start: uint64(block.timestamp),
            cliff: cliffSeconds,
            duration: durationSeconds
        }); 

    }


    function claim() external  NonReentrant{
        Grant storage grant = grants[msg.sender];
        require(grant.total > 0, "no grant");
        require(block.timestamp >= grant.start + grant.cliff, "cliff not reached");

        grant.claimed = grant.total;
        TOKEN.mint(msg.sender, grants[msg.sender].total - grant.claimed);
    
    }                

    function vestedOf(address user) external view returns (uint256){
        return grants[user].total;
    }
}