// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Minimal Pure Super Token
/// @author jtriley.eth changed by shinra-corp.eth
/// @notice No pre-minted supply.
contract MintablePureSuperToken is SuperTokenBase, Ownable {

	/// @dev Upgrades the super token with the factory, then initializes.
    /// @param factory super token factory for initialization
	/// @param name super token name
	/// @param symbol super token symbol
    function initialize(
        address factory,
        string memory name,
        string memory symbol,
        address minter
    ) external {
        _initialize(factory, name, symbol);
        transferOwnership(minter);
    }

    /// @notice Mints tokens, only the owner may do this
    /// @param receiver Receiver of minted tokens
    /// @param amount Amount to mint
    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount, "");
    }

}
