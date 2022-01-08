// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenBase} from "./base/SuperTokenBase.sol";
import {UUPSProxy} from "./utils/UUPSProxy.sol";
import {CallHelper} from "./utils/CallHelper.sol";

/// @title Super Token with permissioned minting
/// @author jtriley.eth
/// @notice Minting is permissioned to a single address in this implementation
contract MintableSuperToken is SuperTokenBase {
	/// @notice Thrown when caller is not the minter
	error OnlyMinter();

	/// @notice Emitted when minting permission is set
	/// @param lastMinter previous minter or zero address if first minter
	/// @param newMinter new minter or zero address if minting is relinquished
	event MinterSet(address indexed lastMinter, address indexed newMinter);

	/// @notice Address with minting permissions
	address public minter;

	constructor(address minter_) {
		minter = minter_;
		emit MinterSet(address(0), minter_);
	}

	/// @notice restricts function call to the minter
	modifier onlyMinter() {
		if (msg.sender != minter) revert OnlyMinter();
		_;
	}

	/// @notice Mints tokens to recipient if caller is the mitner
	/// @param recipient address to which the tokens are minted
	/// @param amount amount of tokens to mint
	/// @param userData optional user data for IERC777Recipient callbacks
	function mint(
		address recipient,
		uint256 amount,
		bytes memory userData
	) external virtual onlyMinter {
		// ISuperToken.selfMint(address,uint256,bytes);
		CallHelper._call(
			address(this),
			abi.encodeWithSelector(0xc68d4283, recipient, amount, userData)
		);
	}

    /// @notice Transfers mint permissions
    /// @param newMinter new minter address or zero address if minting relinquished
	function setMinter(address newMinter) external onlyMinter {
		address lastMinter = minter;
		minter = newMinter;
		emit MinterSet(lastMinter, newMinter);
	}
}
