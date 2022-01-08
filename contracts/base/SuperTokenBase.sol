// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenStorage} from "../utils/SuperTokenStorage.sol";
import {UUPSProxy} from "../utils/UUPSProxy.sol";
import {CallHelper} from "../utils/CallHelper.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Abstract contract with initializer for super token
/// @author jtriley.eth
/// @notice The initial supply may be zero, in the event the token is mintable.
abstract contract SuperTokenBase is SuperTokenStorage, UUPSProxy {
	/// @notice Initializes the super token only once
	/// @param name super token name
	/// @param symbol super token symbol
	/// @param initialRecipient to whom the initial supply is minted
	/// @param initialSupply initially minted supply, can be zero
	/// @param userData optional user data for IERC777Recipient callbacks
	function initialize(
		string memory name,
		string memory symbol,
		address initialRecipient,
		uint256 initialSupply,
		bytes memory userData
	) external virtual {
		// ISuperToken.initialize(address,uint8,string,string);
		CallHelper._call(
			address(this),
			abi.encodeWithSelector(0x42fe0980, address(0), 18, name, symbol)
		);
		if (initialSupply > 0) {
			// ISuperToken.selfMint(address,uint256,bytes);
			CallHelper._call(
				address(this),
				abi.encodeWithSelector(
					0xc68d4283,
					initialRecipient,
					initialSupply,
					userData
				)
			);
		}
	}
}
