// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

// This file contains everything we need for a minimal Pure SuperToken.

// This abstract contract provides storage padding for the proxy
import {CustomSuperTokenBase} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
// Implementation of UUPSProxy (see https://eips.ethereum.org/EIPS/eip-1822)
import {UUPSProxy} from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";
// Superfluid framework interfaces we need
import {
    ISuperToken,
    ISuperTokenFactory,
    IERC20
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/// @title The Proxy contract for a Pure SuperToken with preminted initial supply.
contract PureSuperTokenProxy is CustomSuperTokenBase, UUPSProxy {
    // This shall be invoked exactly once after deployment, needed for the token contract to become operational.
    function initialize(
        ISuperTokenFactory factory,
        string memory name,
        string memory symbol,
        address receiver,
        uint256 initialSupply
    ) external {
        // This call to the factory invokes `UUPSProxy.initialize`, which connects the proxy to the canonical SuperToken implementation.
        // It also emits an event which facilitates discovery of this token.
        ISuperTokenFactory(factory).initializeCustomSuperToken(address(this));

        // This initializes the token storage and sets the `initialized` flag of OpenZeppelin Initializable.
        // This makes sure that it will revert if invoked more than once.
        ISuperToken(address(this)).initialize(IERC20(address(0)), 18, name, symbol);

        // This mints the specified initial supply to the specified receiver.
        ISuperToken(address(this)).selfMint(receiver, initialSupply, "");
    }
}

// The token interface is just an alias of ISuperToken
// since we need no custom logic (other than for initialization) in the proxy.
interface IPureSuperToken is ISuperToken {}
