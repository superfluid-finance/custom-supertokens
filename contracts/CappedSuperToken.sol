// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Capped (maximum supply limit) Mintable Pure Super Token.
/// @author jtriley.eth
/// @notice Mint permission set in initializer, transferrable
contract CappedSuperToken is SuperTokenBase, Ownable {

	/// @notice Thrown when supply limit would be exceeded
	error SupplyCapped();

	/// @notice supply cap
	/// @dev not `immutable` unless set in constructor, which isn't possible
	///      so omitting functions that could write this variable will suffice.
	uint256 public maxSupply;

	/// @notice Initializes the super token only once IF it does not exceed supply cap
	/// @param factory Super Token factory for initialization
	/// @param name Name of Super Token
	/// @param symbol Symbol of Super Token
	/// @param _maxSupply Immutable max supply
	function initialize(
		address factory,
		string memory name,
		string memory symbol,
		uint256 _maxSupply
	) external {
		_initialize(factory, name, symbol);
		maxSupply = _maxSupply;
	}

	/// @notice Mints tokens to recipient if caller is the mitner AND max supply will not be exceeded
	/// @param recipient address to which the tokens are minted
	/// @param amount amount of tokens to mint
	/// @param userData optional user data for IERC777Recipient callbacks
	function mint(
		address recipient,
		uint256 amount,
		bytes memory userData
	) public onlyOwner {
		if (_totalSupply() + amount > maxSupply) revert SupplyCapped();
		// MintableSuperToken._mint(address,uint256,bytes)
		_mint(recipient, amount, userData);
	}
}
