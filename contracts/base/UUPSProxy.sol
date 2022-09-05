// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

/// @title UUPS Proxy implementation contract
/// @author jtriley.eth
/// @notice Stores the logic contract's address at the _IMPLEMENTATION_SLOT
/// @dev `initializeProxy(address)` is called by the Super Token Factory
/// The call to the factory should be in the same transaction to avoid being
/// front run
contract UUPSProxy is Proxy {
	/// @notice Thrown when the logic contract address is zero
	error ZeroAddress();

	/// @notice Thrown when the logic contract has been set
	error Initialized();

	/// @notice Precomputed from the following for gas savings
	/// bytes32(uint256(keccak256("eip1967.proxy.implementation") - 1));
	bytes32 internal constant _IMPLEMENTATION_SLOT =
		0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	/// @notice Stores the logic contract address only once.
	/// @dev Called by the SuperTokenFactory contract on upgrade
	/// @param initialAddress logic contract address
	function initializeProxy(address initialAddress) external {
		if (initialAddress == address(0)) revert ZeroAddress();
		if (_implementation() != address(0)) revert Initialized();
		assembly {
			sstore(_IMPLEMENTATION_SLOT, initialAddress)
		}
	}

	/// @notice Reads logic contract from precomputed slot
	/// @return impl Logic contract address
	function _implementation()
		internal
		view
		virtual
		override
		returns (address impl)
	{
		assembly {
			impl := sload(_IMPLEMENTATION_SLOT)
		}
	}
}
