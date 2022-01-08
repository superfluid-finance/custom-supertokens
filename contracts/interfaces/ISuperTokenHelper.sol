// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Helper to avoid using `.call()` syntax
/// @author jtriley.eth
/// @notice This is not a complete interface, but rather a helper for upgradeable contracts
/// This should NOT be inherited, but to be used as: ISuperTokenHelper(address).functionName()
interface ISuperTokenHelper {
	/// @notice Initializes the super token contract after upgrading
	/// @param underlyingToken token address of underlying token or zero address for native
	/// @param underlyingDecimals underlying token's decimals or 18 for native
	/// @param name super token name
	/// @param symbol super token symbol
	function initialize(
		IERC20 underlyingToken,
		uint8 underlyingDecimals,
		string calldata name,
		string calldata symbol
	) external;

	/// @notice Mints new tokens to the account
	/// @dev reverts if address(this) is not the caller
	/// @param account mint recipient
	/// @param amount mint amount
	/// @param userData optional data for IERC777Recipient contracts
	function selfMint(
		address account,
		uint256 amount,
		bytes memory userData
	) external;

    /// @
}
