// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperTokenFactory} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";

/// @title Abstract base contract for deploying super tokens in a single transaction
/// @author jtriley.eth
/// @notice Super tokens should be deployed, upgraded, AND initialized in the same
///         transaction to avoid front running opportunities
abstract contract SuperTokenDeployerBase {
	/// @notice Should be called by the super token deployer contract BEFORE initialize
	/// @param factory SuperTokenFactory address for calling the upgrade
	/// @param bytecode Custom super token bytecode, accessible via type(CustomSuperTokenContract).creationCode
	/// @param salt Salt of 32 bytes, should be pseudorandom, cryptographic randomness is not required
    /// @return _superToken Deterministic super token address computed by create2 opcode
	function _deployAndUpgrade(
		address factory,
		bytes memory bytecode,
		bytes32 salt
	) internal returns (address _superToken) {
		assembly {
			_superToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
		}
		ISuperTokenFactory(factory).initializeCustomSuperToken(_superToken);
	}
}
