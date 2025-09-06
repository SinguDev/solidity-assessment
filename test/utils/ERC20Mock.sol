// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20 } from "@openzeppelin-contracts-5.4.0/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("MOCK", "MOCK") { }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
