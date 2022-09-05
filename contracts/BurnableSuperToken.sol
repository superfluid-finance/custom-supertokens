// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Burnable Pure Super Token
/// @author jtriley.eth
/// @notice This does not perform checks when burning
contract BurnableSuperToken is SuperTokenBase {

	/// @notice Initializer, used AFTER factory upgrade
	/// @dev We MUST mint here, there is no other way to mint tokens
	/// @param name Name of Super Token
	/// @param symbol Symbol of Super Token
	/// @param factory Super Token factory for initialization
	/// @param initialSupply Initial token supply to pre-mint
	/// @param receiver Receiver of pre-mint
	/// @param userData Arbitrary user data for pre-mint
	function initialize(
		string memory name,
		string memory symbol,
		address factory,
		uint256 initialSupply,
		address receiver,
		bytes memory userData
	) external {
		_initialize(name, symbol, factory);
		_mint(receiver, initialSupply, userData);
	}

	/// @notice Burns from message sender
	/// @param amount Amount to burn
	function burn(uint256 amount, bytes memory userData) external {
		_burn(msg.sender, amount, userData);
	}
}
