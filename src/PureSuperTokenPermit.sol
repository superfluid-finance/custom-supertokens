// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IERC20Permit} from "@openzeppelin-v5/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {ECDSA} from "@openzeppelin-v5/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin-v5/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin-v5/contracts/utils/Nonces.sol";

import {CustomSuperTokenBase} from
    "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
import {UUPSProxy} from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";
import {
    ISuperToken,
    ISuperTokenFactory,
    IERC20
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {
    ISuperToken,
    ISuperTokenFactory,
    IERC20
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/// @title The Proxy contract for a Pure SuperToken with permit and preminted initial supply.
contract PureSuperTokenPermitProxy is CustomSuperTokenBase, UUPSProxy, IERC20Permit, EIP712, Nonces {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @dev Permit deadline has expired.
    error ERC2612ExpiredSignature(uint256 deadline);

    /// @dev Mismatched signature.
    error ERC2612InvalidSigner(address signer, address owner);

    constructor(string memory name) EIP712(name, "1") {}

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

    // ============================ IERC20Permit ============================

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        ISuperToken(address(this)).selfApproveFor(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// The token interface is just an alias of ISuperToken
// since we need no custom logic (other than for initialization) in the proxy.
interface IPureSuperTokenPermit is ISuperToken, IERC20Permit {}
