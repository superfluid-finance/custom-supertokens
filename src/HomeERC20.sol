// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin-v5/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-v5/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin-v5/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * Stock OpenZeppelin ERC20 with ERC-5805 based Votes extension
 */
contract HomeERC20 is ERC20, ERC20Permit, ERC20Votes {
    constructor(string memory name, string memory symbol, address treasury, uint256 initialSupply)
        ERC20(name, symbol) ERC20Permit(name)
    {
        _mint(treasury, initialSupply);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}