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

/// @title FOT (Fee on Transfer) Token
/// trivial implementation using a fixed fee amount per tx, added to the actual transfer amount.
/// @notice CustomSuperTokenBase MUST be the first inherited contract, otherwise the storage layout may get corrupted
contract FOTTokenProxy is CustomSuperTokenBase, UUPSProxy, Ownable {
    uint256 public feePerTx;
    address public feeRecipient;

    constructor(uint256 _feePerTx, address _feeRecipient) {
        feePerTx = _feePerTx;
        feeRecipient = _feeRecipient;
    }

    function setFeeConfig(uint256 _feePerTx, address _feeRecipient) external onlyOwner {
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

    // ERC20 functions we want to intercept and add custom behavior to

    function transferFrom(address holder, address recipient, uint256 amount)
        public returns (bool)
    {
        // get the fee
        ISuperToken(address(this)).selfTransferFrom(holder, msg.sender, feeRecipient, feePerTx);
        // (external) call into the implementation contract.

        // do the actual tx
        ISuperToken(address(this)).selfTransferFrom(holder, msg.sender, recipient, amount);
        return true; // returns true if it didn't revert
    }

    function transfer(address recipient, uint256 amount)
        public returns (bool)
    {
        return transferFrom(msg.sender, recipient, amount);
    }
}

// TODO: create interfaces IFOTTokenCustom, IFOTToken - see https://github.com/superfluid-finance/protocol-monorepo/blob/dev/packages/ethereum-contracts/contracts/interfaces/tokens/ISETH.sol
