// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import { CustomSuperTokenBase } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
import { UUPSProxy } from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";
import {
    ISuperToken,
    ISuperTokenFactory,
    IERC20
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Custom methods of this token
interface IFOTTokenCustom {
    // admin interface
    function setFeeConfig(uint256 _feePerTx, address _feeRecipient) external /*onlyOwner*/;

    // subset of ISuperToken/IERC20 intercepted in the proxy in order to add a fee
    function transferFrom(address holder, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/// @title FOT (Fee on Transfer) Token
/// Simple implementation of a Pure SuperToken taking a constant fee for every transfer operation.
/// @notice CustomSuperTokenBase MUST be the first inherited contract, otherwise the storage layout breaks.
contract FOTTokenProxy is CustomSuperTokenBase, UUPSProxy, Ownable, IFOTTokenCustom {
    uint256 public feePerTx; // amount detracted as fee per tx
    address public feeRecipient; // receiver of the fee

    event FeeConfigSet(uint256 feePerTx, address feeRecipient);

    constructor(uint256 _feePerTx, address _feeRecipient) {
        feePerTx = _feePerTx;
        feeRecipient = _feeRecipient;
    }

    function initialize(
        ISuperTokenFactory factory,
        string memory name,
        string memory symbol
    ) external {
        ISuperTokenFactory(factory).initializeCustomSuperToken(address(this));
        ISuperToken(address(this)).initialize(IERC20(address(0)), 18, name, symbol);
    }

    // ======= IFOTTokenCustom =======

    function setFeeConfig(uint256 _feePerTx, address _feeRecipient) external override onlyOwner {
        feePerTx = _feePerTx;
        feeRecipient = _feeRecipient;
        emit FeeConfigSet(_feePerTx, _feeRecipient);
    }

    function transferFrom(address holder, address recipient, uint256 amount)
        external override returns (bool)
    {
        _transferFrom(holder, recipient, amount);
        return true; // returns true if it didn't revert
    }

    function transfer(address recipient, uint256 amount)
        external override returns (bool)
    {
        _transferFrom(msg.sender, recipient, amount);
        return true;
    }

    // ======= Internal =======

    function _transferFrom(address holder, address recipient, uint256 amount) internal {
        // get the fee
        ISuperToken(address(this)).selfTransferFrom(holder, msg.sender, feeRecipient, feePerTx);
        // (external) call into the implementation contract.

        // do the actual tx
        ISuperToken(address(this)).selfTransferFrom(holder, msg.sender, recipient, amount);
    }
}

interface IFOTToken is ISuperToken, IFOTTokenCustom {
    // we need to explicitly tell the compiler about the methods present in both base interfaces
    function transferFrom(address holder, address recipient, uint256 amount) external override(ISuperToken, IFOTTokenCustom) returns (bool);
    function transfer(address recipient, uint256 amount) external override(ISuperToken, IFOTTokenCustom) returns (bool);
}