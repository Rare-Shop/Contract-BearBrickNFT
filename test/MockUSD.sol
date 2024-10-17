// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSD is ERC20 {
    // constructor() ERC20("Mock USDT", "USDT") {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 1000 USDT to the deployer
        _mint(msg.sender, 1000 * 10**18);
    }
}