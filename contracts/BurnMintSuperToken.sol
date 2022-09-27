// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Burnable and Mintable Pure Super Token
/// @author jtriley.eth
/// @notice This does not perform checks when burning
contract BurnMintSuperToken is SuperTokenBase, AccessControl {
	/// @notice Minter Role
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	/// @notice Burner Role
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

	/// @notice Initializer, used AFTER factory upgrade
	/// @dev We MUST mint here, there is no other way to mint tokens
	/// @param factory Super Token factory for initialization
	/// @param name Name of Super Token
	/// @param symbol Symbol of Super Token
	/// @param initialSupply Initial token supply to pre-mint
	/// @param receiver Receiver of pre-mint
	/// @param userData Arbitrary user data for pre-mint
	function initialize(
		address factory,
		string memory name,
		string memory symbol,
		uint256 initialSupply,
		address receiver,
		bytes memory userData
	) external {
		_initialize(factory, name, symbol);
		_mint(receiver, initialSupply, userData);
	}

	/// @notice Mints tokens, only the owner may do this
	/// @param receiver Receiver of minted tokens
	/// @param amount Amount to mint
	function mint(
		address receiver,
		uint256 amount,
		bytes memory userData
	) external onlyRole(MINTER_ROLE) {
		_mint(receiver, amount, userData);
	}

	/// @notice Burns from message sender
	/// @param amount Amount to burn
	function burn(uint256 amount, bytes memory userData)
		external
		onlyRole(BURNER_ROLE)
	{
		_burn(msg.sender, amount, userData);
	}
}
