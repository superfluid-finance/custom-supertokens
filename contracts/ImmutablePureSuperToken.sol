// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenBase} from "./base/SuperTokenBase.sol";
import {SuperTokenStorage} from "./base/SuperTokenStorage.sol";
import { ImmutableSuperTokenBase } from "./base/ImmutableSuperTokenBase.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

/// @title Minimal Pure Super Token
/// @author jtriley.eth
/// @notice Pre-minted supply. This is includes no custom logic. Used in `PureSuperTokenDeployer`
contract ImmutablePureSuperToken is ImmutableSuperTokenBase  {

	/// @dev Upgrades the super token with the factory, then initializes.
	/// @param name super token name
	/// @param symbol super token symbol
	/// @param receiver Receiver of pre-mint
	/// @param initialSupply Initial token supply to pre-mint
    function initialize (
        string memory name,
        string memory symbol,
        address receiver,
        uint256 initialSupply
    ) external {
        _initialize(name, symbol);
        _mint(receiver, initialSupply, "");
    }
    
}
