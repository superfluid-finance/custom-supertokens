// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenBase, ISuperToken} from "./base/SuperTokenBase.sol";
import {IMaticBridgedSuperTokenCustom} from "./interfaces/IMaticBridgedSuperToken.sol";

import {ISuperfluid} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/**
 * @title Pure Super Token controlled by the Polygon PoS Bridge
 * @author Superfluid
 * @dev Pure SuperToken with interfaces for the Polygon PoS bridge to mint and burn.
 * @dev See https://docs.polygon.technology/docs/develop/ethereum-matic/pos/mapping-assets/
 */
contract MaticBridgedSuperToken is SuperTokenBase, IMaticBridgedSuperTokenCustom {
    /// address of the bridge contract interacting with this token contract
    address public childChainManager;

    constructor(address childChainManager_) {
        childChainManager = childChainManager_;
    }

    /// @notice Initializes the super token
    /// @param factory Super Token factory for initialization
    /// @param name Name of Super Token
    /// @param symbol Symbol of Super Token
    function initialize(
        address factory,
        string memory name,
        string memory symbol
    ) external {
        _initialize(factory, name, symbol);
    }

    /// @inheritdoc IMaticBridgedSuperTokenCustom
    function deposit(address user, bytes calldata depositData) external override {
        require(msg.sender == childChainManager, "MBST: no permission to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        ISuperToken(address(this)).selfMint(user, amount, new bytes(0));
    }

    /// @inheritdoc IMaticBridgedSuperTokenCustom
    function withdraw(uint256 amount) external override {
        ISuperToken(address(this)).selfBurn(msg.sender, amount, new bytes(0));
    }

    /// @inheritdoc IMaticBridgedSuperTokenCustom
    /// @notice allows Superfluid governance to update the childChainManager
    function updateChildChainManager(address newChildChainManager) external override {
        address host = ISuperToken(address(this)).getHost();
        address gov = address(ISuperfluid(host).getGovernance());
        require(msg.sender == gov, "MBST: only governance allowed");

        childChainManager = newChildChainManager;
        emit ChildChainManagerChanged(newChildChainManager);
    }
}
