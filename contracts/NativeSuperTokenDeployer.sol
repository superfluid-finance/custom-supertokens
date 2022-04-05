// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {NativeSuperToken} from "./NativeSuperToken.sol";

/// @title Native Super Token deployment 'Factory'
/// @author jtriley.eth
/// @dev Notice this is not the `SuperTokenFactory`, which handles upgrading contracts. This is a
/// minimal contract simply to deploy, upgrade, and initialize the most minimal super token possible
contract NativeSuperTokenDeployer {

    /// @dev Emitted when new super token deployed and initialized
    /// @param newSuperToken New Super Token address
    event SuperTokenDeployed(address newSuperToken);

    /// @dev Super Token factory address
    address internal immutable _factory;

    constructor(address factory) {
        _factory = factory;
    }

    /// @notice Deploys a new Super Token
    /// @param name Name for Super Token
    /// @param symbol Symbol for Super Token
    /// @param receiver Receiver of pre-mint
    /// @param initialSupply Initially minted supply
    /// @return newSuperToken New Super Token address
    /// @dev Emits `SuperTokenDeployed`
    function deploySuperToken(
        string memory name,
        string memory symbol,
        address receiver,
        uint256 initialSupply
    ) external returns (address newSuperToken) {

        // (string . address . string) with `abi.encodePacked` is more efficient and prevents a
        // hashing collision. See https://swcregistry.io/docs/SWC-133
        newSuperToken = _create2(keccak256(abi.encodePacked(name, msg.sender, symbol)));

        // NativeSuperToken has a payable fallback in `Proxy`
        // Proxy -> UUPSProxy -> SuperTokenBase -> NativeSuperToken
        NativeSuperToken(payable(newSuperToken)).initialize(
            name,
            symbol,
            _factory,
            receiver,
            initialSupply
        );

        emit SuperTokenDeployed(newSuperToken);
    }

    /// @dev Creates a new contract with deterministic address using `create2`
    /// @param salt unique 32 byte salt
    /// @return newSuperToken Address of newly created super token
    function _create2(bytes32 salt) internal returns (address newSuperToken) {
        bytes memory _bytecode = type(NativeSuperToken).creationCode;
        assembly {
            newSuperToken := create2(
                0,
                add(_bytecode, 32),
                mload(_bytecode),
                salt
            )
        }
    }

}
