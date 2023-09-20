// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

// This file contains everything we need for a customized Pure SuperToken.
// It imports needed dependencies from the Superfluid framework and OpenZeppelin.
// The custom logic is added to the proxy contract, which inherits from UUPSProxy.
// We also provide an interface for the custom token, which consists of the intersection of ISuperToken and the token's custom interface.

// This abstract contract provides storage padding for the proxy
import { CustomSuperTokenBase } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
// Implementation of UUPSPoxy (see https://eips.ethereum.org/EIPS/eip-1822)
import { UUPSProxy } from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";
// Superfluid framework interfaces we need (incl. IERC20)
import { ISuperToken, ISuperTokenFactory, IERC20} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
// Ownable for the admin interface - not needed for tokens without admin interface
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Custom interface of our token.
// Also includes methods of ISuperToken we intercept in order to change their behavior.
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
    // Thanks to the storage padding provided by CustomSuperTokenBase, we can safely add storage variables here
    uint256 public feePerTx; // amount detracted as fee per tx
    address public feeRecipient; // receiver of the fee

    // event emitted when the fee config is set
    event FeeConfigSet(uint256 feePerTx, address feeRecipient);

    constructor(uint256 _feePerTx, address _feeRecipient) {
        setFeeConfig(_feePerTx, _feeRecipient);
    }

    // This shall be invoked exactly once after deployment, needed for the token contract to become operational.
    function initialize(ISuperTokenFactory factory, string memory name, string memory symbol) external {
        // This call to the factory invokes `UUPSProxy.initialize`, which connects the proxy to the canonical SuperToken implementation.
        // It also emits an event which facilitates discovery of this token.
        ISuperTokenFactory(factory).initializeCustomSuperToken(address(this));
        // This initializes the token storage and sets the `initialized` flag of OpenZeppelin Initializable.
        ISuperToken(address(this)).initialize(IERC20(address(0)), 18, name, symbol);
    }

    // ======= IFOTTokenCustom =======

    // admin function to set the fee config, permissioned by Ownable
    function setFeeConfig(uint256 _feePerTx, address _feeRecipient) public override onlyOwner {
        feePerTx = _feePerTx;
        feeRecipient = _feeRecipient;
        emit FeeConfigSet(_feePerTx, _feeRecipient);
    }

    // intercepted `ERC20.transferFrom`
    function transferFrom(address holder, address recipient, uint256 amount) external override returns (bool) {
        _transferFrom(holder, recipient, amount);
        return true;
    }

    // intercepted `ERC20.transfer`
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transferFrom(msg.sender, recipient, amount);
        return true;
    }

    // ======= Internal =======

    // In order to achieve the desired behaviour of the intercepted transfer methods,
    // we use the "self" methods of the canonical SuperToken implementation to do 2 transfers: one to the actual recipient and one to the fee recipient.
    // The self methods can only be called by the token contract itself (modifier `onlySelf`).
    // This works because by triggering an external call via `this.method`, we invoke the fallback function of this proxy,
    // which does a delegate call to the canonical implementation it points to.
    // In the context of a delegate call, `address(this)` resolves to the address of the caller, which in this case is this proxy contract.
    function _transferFrom(address holder, address recipient, uint256 amount) internal {
        // get the fee
        ISuperToken(address(this)).selfTransferFrom(holder, msg.sender, feeRecipient, feePerTx);

        // do the actual tx
        ISuperToken(address(this)).selfTransferFrom(holder, msg.sender, recipient, amount);
    }
}

// This interface makes it more convenient for Dapps to interface with the token,
// unifying the APIs implemented by the proxy and by the canonical implementation into a single interface.
interface IFOTToken is ISuperToken, IFOTTokenCustom {
    // We need to re-declare the methods present in both base interfaces to avoid compiler complaints.
    function transferFrom(address holder, address recipient, uint256 amount) external override(ISuperToken, IFOTTokenCustom) returns (bool);
    function transfer(address recipient, uint256 amount) external override(ISuperToken, IFOTTokenCustom) returns (bool);
}