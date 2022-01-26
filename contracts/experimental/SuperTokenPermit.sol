// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {SuperTokenBase} from "../base/SuperTokenBase.sol";
import {IForwarder} from "../utils/IForwarder.sol";

/// @title Burnable and Mintable Super Token
/// @author jtriley.eth
/// @notice This does not perform checks when burning
contract SuperTokenPermit is SuperTokenBase, AccessControl {

	// ISuperfluid.Operation
	struct Operation {
		uint32 op;
		address target;
		bytes data;
	}

	/// @notice Minter Role
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	/// @notice Burner Role
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @dev Hard coded gas limit, may be mutable
    uint256 internal constant _GAS_LIMIT = 3_000_000;

    /// @dev Hard coded meta-tx gas cost, may be mutable
    uint256 internal _tokenGasPrice = 0;

    /// @dev Hard coded batch ID, may be mutable
    uint256 internal _batchId;

    /// @dev Trusted Forwarder
    IForwarder internal _forwarder;

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/// @notice Initializer, used AFTER factory upgrade
	/// @dev We MUST mint here, there is no other way to mint tokens
	/// @param name Name of Super Token
	/// @param symbol Symbol of Super Token
	function initialize(
		string memory name,
		string memory symbol,
        address forwarder
	) external {
		_initialize(name, symbol);
        _forwarder = IForwarder(forwarder);
	}

	/// @notice Mints tokens, only the owner may do this
	/// @param receiver Receiver of minted tokens
	/// @param amount Amount to mint
	function mint(
		address receiver,
		uint256 amount,
		bytes memory userData
	) external onlyRole(MINTER_ROLE) {
		_mint(receiver, amount, userData);
	}

	/// @notice Burns from message sender
	/// @param amount Amount to burn
	function burn(uint256 amount, bytes memory userData)
		external
		onlyRole(BURNER_ROLE)
	{
		_burn(msg.sender, amount, userData);
	}

	/// @notice Allows spender approval with meta-transaction
	/// @param owner Token owner, signer
	/// @param spender Address approved for spending
	/// @param value Amount to be approved
	/// @param deadline Deadline for approval call
	/// @param v `v` component of SECP256K1 signature
	/// @param r `r` component of SECP256K1 signature
	/// @param s `s` component of SECP256K1 signature
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
        _forwarder.executePersonalSign(
            _generateRequest(owner, spender, value, deadline),
            abi.encodePacked(r, s, v)
        );
	}

    /// @dev Generates an `approve` request to be routed
    ///      address(this) -> Forwarder -> Superfluid -> SuperToken
	/// @param owner Token owner, signer
	/// @param spender Address approved for spending
	/// @param amount Amount to be approved
	/// @param deadline Deadline for approval call
	function _generateRequest(address owner, address spender, uint256 amount, uint256 deadline)
		internal
		view
		returns (IForwarder.ERC20ForwardRequest memory)
	{
        // MUST declare like this due to abi encoding rules
        Operation[1] memory ops = [
            Operation({
                op: 1,
                target: address(this),
                data: abi.encode(spender, amount)
            })
        ];

        bytes memory callData = abi.encodeWithSignature(
            "forwardBatchCall((uint32,address,bytes)[])",
            ops
        );

        return IForwarder.ERC20ForwardRequest({
            from: owner,
            to: ISuperToken(address(this)).getHost(),
            token: address(this),
            txGas: _GAS_LIMIT,
            tokenGasPrice: _tokenGasPrice,
            batchId: _batchId,
            batchNonce: _forwarder.getNonce(owner, _batchId),
            deadline: deadline,
            data: callData
        });
    }
}
