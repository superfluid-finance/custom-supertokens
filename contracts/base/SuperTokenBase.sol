// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenStorage} from "../utils/SuperTokenStorage.sol";
import {UUPSProxy} from "../utils/UUPSProxy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

/// @title Abstract contract with initializer for super token
/// @author jtriley.eth
/// @notice The initial supply may be zero, in the event the token is mintable.
/// @dev Inheriting contracts MUST have an initializer calling this function!
abstract contract SuperTokenBase is SuperTokenStorage, UUPSProxy {
	/// @notice Initializes the super token only once
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
}
