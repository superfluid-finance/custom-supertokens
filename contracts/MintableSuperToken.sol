// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Mintable Pure Super Token
/// @author jtriley.eth
/// @notice Only the owner may mint
contract MintableSuperToken is SuperTokenBase, Ownable {
	
    /// @notice Initializer, used AFTER factory upgrade
	/// @param factory Super token factory for initialization
    /// @param name Name of Super Token
    /// @param symbol Symbol of Super Token
    function initialize(address factory, string memory name, string memory symbol) external {
        _initialize(factory, name, symbol);
    }

	/// @notice Mints tokens, only the owner may do this
	/// @param receiver Receiver of minted tokens
	/// @param amount Amount to mint
	function mint(address receiver, uint256 amount, bytes memory userData) external onlyOwner {
		_mint(receiver, amount, userData);
	}
}
