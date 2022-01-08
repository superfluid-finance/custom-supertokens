// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenBase} from "./base/SuperTokenBase.sol";
import {UUPSProxy} from "./utils/UUPSProxy.sol";
import {CallHelper} from "./utils/CallHelper.sol";

/// @title Super Token with permissioned burning
/// @author jtriley.eth
/// @notice Burning is permissioned to a single address in this implementation
contract BurnableSuperToken is SuperTokenBase {
	/// @notice Thrown when caller is not the burner
	error OnlyBurner();

	/// @notice Emitted when burner permission is set
	/// @param lastBurner previous burner or zero address if first burner
	/// @param newBurner new burner or zero address if burning is relinquished
	event BurnerSet(address indexed lastBurner, address indexed newBurner);

	/// @notice Address with burner permissions
	address public burner;

	constructor(address burner_) {
		burner = burner_;
		emit BurnerSet(address(0), burner_);
	}

	/// @notice restricts function call to the burner
	modifier onlyBurner() {
		if (msg.sender != burner) revert OnlyBurner();
		_;
	}

	/// @notice Burns tokens to recipient if caller is the burner
	/// @param amount amount of tokens to be burned
	/// @param userData optional user data for IERC777Recipient callbacks
	function burn(
		uint256 amount,
		bytes memory userData
	) external onlyBurner {
		// ISuperToken.selfBurn(address,uint256,bytes);
		CallHelper._call(
			address(this),
			abi.encodeWithSelector(0x9d876741, msg.sender, amount, userData)
		);
	}

	/// @notice Transfers burn permissions
	/// @param newBurner new burner address or zero address if burning is relinquished
	function setBurner(address newBurner) external onlyBurner {
		address lastBurner = burner;
		burner = newBurner;
		emit BurnerSet(lastBurner, newBurner);
	}
}
