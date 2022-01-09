// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

import {SuperTokenBase} from "./SuperTokenBase.sol";

/// @title Abstract Super Token for burning after deployment
/// @author jtriley.eth
/// @notice This contract does not perform checks for permissions or limits
abstract contract BurnableSuperToken is SuperTokenBase {
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
}
