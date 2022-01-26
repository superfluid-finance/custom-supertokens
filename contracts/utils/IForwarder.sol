// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface extracted from Biconomy Source Code.
/// @author jtriley.eth
/// @notice This allows us to interface with the Trusted Forwarder contract that
///         will call the respective functions on the Superfluid host.
interface IForwarder {

    /// @dev Full ERC20 Forward Request, Not all fields are relevant
    /// @param from Account that signs the metatransaction (sender)
    /// @param to Target address to execute function call (Superfluid host)
    /// @param token Token to collect meta-tx fees in (not applicable)
    /// @param txGas Gas provided for call execution
    /// @param tokenGasPrice Token amount for meta-tx fee (not applicable)
    /// @param batchId Unique ID of meta-tx batch
    /// @param batchNonce Nonce unique to `from` and `batchId`
    /// @param deadliine Execution deadline timestamp (zero for no deadline)
    /// @param data Arbitrary data to execute on `to` (call agreement)
	struct ERC20ForwardRequest {
		address from;
		address to;
		address token;
		uint256 txGas;
		uint256 tokenGasPrice;
		uint256 batchId;
		uint256 batchNonce;
		uint256 deadline;
		bytes data;
	}

    /// @notice Gets nonce value with a given account and batch ID
    /// @param account Account for nonce fetching
    /// @param batchId Id of batch for nonce fetching
    /// @return nonce Returned Nonce
	function getNonce(address account, uint256 batchId)
		external
		view
		returns (uint256 nonce);

    /// @notice Verifies SECP256K1 digital signature where signer is `req.from`
    /// @param req Request struct
    /// @param sig SECP256K1 Signature
	function verifyPersonalSign(
		ERC20ForwardRequest calldata req,
		bytes calldata sig
	) external view;

    /// @notice Executes EIP712 meta-transaction if signature is valid
    /// @param req Request struct
    /// @param sig SECP256K1 Signature
    /// @return success True if call was successful
    /// @return ret Returned value from call
	function executePersonalSign(
		ERC20ForwardRequest calldata req,
		bytes calldata sig
	) external returns (bool success, bytes memory ret);
}