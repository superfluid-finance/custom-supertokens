// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

// This file contains show how to create a custom ERC20 Wrapper

// This abstract contract provides storage padding for the proxy
import { CustomSuperTokenBase } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
// Implementation of UUPSProxy (see https://eips.ethereum.org/EIPS/eip-1822)
import { UUPSProxy } from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";
// Superfluid framework interfaces we need
import { ISuperToken, ISuperTokenFactory, IERC20Metadata } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/// @title The Proxy contract for a Custom ERC20 Wrapper
contract CustomERC20WrapperProxy is CustomSuperTokenBase, UUPSProxy {
	// This shall be invoked exactly once after deployment, needed for the token contract to become operational.
	function initialize(
		IERC20Metadata underlyingToken,
		ISuperTokenFactory factory,
		string memory name,
		string memory symbol
	) external {
		// This call to the factory invokes `UUPSProxy.initialize`, which connects the proxy to the canonical SuperToken implementation.
		// It also emits an event which facilitates discovery of this token.
		factory.initializeCustomSuperToken(address(this));

		// This initializes the token storage and sets the `initialized` flag of OpenZeppelin Initializable.
		// This makes sure that it will revert if invoked more than once.
		ISuperToken(address(this)).initialize(
			underlyingToken,
			underlyingToken.decimals(),
			name,
			symbol
		);
	}

	// add custom functionality here...
}

interface ICustomERC20Wrapper is ISuperToken {}
