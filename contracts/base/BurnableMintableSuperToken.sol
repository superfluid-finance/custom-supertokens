// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

import {SuperTokenBase} from "./SuperTokenBase.sol";

/// @title Abstract Super Token for minting and burning after deployment
/// @author jtriley.eth
/// @notice This contract does not perform checks for permissions or limits
abstract contract BurnableMintableSuperToken is SuperTokenBase {
	/// @notice Internal burn, calling function should perform important checks!
	/// @param from Address from which to burn tokens
	/// @param amount Amount to burn
	/// @param userData Optional user data for ERC777 send callback
	function _burn(
		address from,
		uint256 amount,
		bytes memory userData
	) internal {
		ISuperToken(address(this)).selfBurn(from, amount, userData);
	}

	/// @notice Internal mint, calling function should perform important checks!
	/// @param account Address receiving minted tokens
	/// @param amount Amount of tokens minted
	/// @param userData Optional user data for ERC777 send callback
	function _mint(
		address account,
		uint256 amount,
		bytes memory userData
	) internal {
		ISuperToken(address(this)).selfMint(account, amount, userData);
	}
}
