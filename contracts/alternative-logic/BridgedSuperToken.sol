// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import { SuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import { SuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperfluidToken.sol";
import { ISuperfluid } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IConstantOutflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantOutflowNFT.sol";
import { IConstantInflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantInflowNFT.sol";

interface IMintBurn {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
}

/**
 * This is a variant of the SuperToken logic with the following changes:
 * - simple mint/burn interface which can be called only by a hardcoded BRIDGE_ADDR
 * - update admin changes from host to a hardcoded UPGRADE_ADMIN
 *
 * This allows Pure SuperToken representations (deployments on other than the home chain) like MIVA and FRACTION 
 * to be used with the Connext bridge.
 */
contract BridgedSuperToken is SuperToken, IMintBurn {
    // the account with upgrade permission. In order to change, upgrade to a logic with different value.
    address public immutable UPGRADE_ADMIN;

    // the account with mint/burn permission. In order to change, upgrade to a logic with different value.
    address public immutable BRIDGE_ADDR;

    error NO_PERMISSION();

    constructor(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT,
        address upgradeAdmin,
        address bridgeAddr
    )
        SuperToken(host, constantOutflowNFT, constantInflowNFT)
    {
        UPGRADE_ADMIN = upgradeAdmin;
        BRIDGE_ADDR = bridgeAddr;
    }

    // TODO: shall we use mint/burn with or without hooks? If without, add events

    function burn(address from, uint256 amount) external override {
        if (msg.sender != BRIDGE_ADDR) revert NO_PERMISSION();
        this.selfBurn(from, amount, new bytes(0));
        //SuperfluidToken._mint(from, amount);
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != BRIDGE_ADDR) revert NO_PERMISSION();
        this.selfMint(to, amount, new bytes(0));
        //SuperfluidToken._mint(to, amount);
    }

    // Make the token self-sovereign

    /// IMPORTANT: this function needs to stay in sync with the canonical version of SuperToken
    function updateCode(address newAddress) external override {
        if (msg.sender != UPGRADE_ADMIN) revert NO_PERMISSION();
        // implementation in UUPSProxiable
        _updateCodeAddress(newAddress);

        // @note This is another check to ensure that when updating to a new SuperToken logic contract
        // that we have passed the correct NFT proxy contracts in the construction of the new SuperToken
        // logic contract
        if (
            CONSTANT_OUTFLOW_NFT !=
            SuperToken(newAddress).CONSTANT_OUTFLOW_NFT() ||
            CONSTANT_INFLOW_NFT !=
            SuperToken(newAddress).CONSTANT_INFLOW_NFT()
        ) {
            revert SUPER_TOKEN_NFT_PROXY_ADDRESS_CHANGED();
        }
    }
}