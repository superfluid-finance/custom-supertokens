// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenStorage} from "../utils/SuperTokenStorage.sol";
import {UUPSProxy} from "../utils/UUPSProxy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

/// @title Abstract contract with initializer for super token
/// @author jtriley.eth
/// @dev The initial supply may be zero, in the event the token is mintable.
/// Inheriting contracts MUST have an initializer calling this function!
abstract contract SuperTokenBase is SuperTokenStorage, UUPSProxy {
	/// @dev Initializes the super token only once
	/// @param name super token name
	/// @param symbol super token symbol
	function _initialize(string memory name, string memory symbol) internal {
		ISuperToken(address(this)).initialize(
			IERC20(address(0)),
			18,
			name,
			symbol
		);
	}

	/// @dev Internal mint, calling function should perform important checks!
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

	/// @dev Internal burn, calling function should perform important checks!
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
}
