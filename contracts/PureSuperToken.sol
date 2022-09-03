// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Minimal Pure Super Token
/// @author jtriley.eth
/// @notice Pre-minted supply. This is includes no custom logic. Used in `PureSuperTokenDeployer`
contract PureSuperToken is SuperTokenBase {

	/// @dev Upgrades the super token with the factory, then initializes.
	/// @param name super token name
	/// @param symbol super token symbol
	/// @param factory super token factory for initialization
	/// @param receiver Receiver of pre-mint
	/// @param initialSupply Initial token supply to pre-mint
    function initialize(
        string memory name,
        string memory symbol,
        address factory,
        address receiver,
        uint256 initialSupply
    ) external {
        _initialize(name, symbol, factory);
        _mint(receiver, initialSupply, "");
    }

}
