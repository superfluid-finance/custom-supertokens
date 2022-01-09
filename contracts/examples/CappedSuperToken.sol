// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

import {MintableSuperToken} from "../base/MintableSuperToken.sol";

/// @title Mintable Super Token implementation with permissioned minting
/// @author jtriley.eth
/// @notice Mint permission set in initializer, transferrable
contract CappedSuperToken is MintableSuperToken {
	/// @notice Thrown when address is not authorized to mint
	error OnlyMinter();

	/// @notice Thrown when supply limit would be exceeded
	error SupplyCapped();

    /// @notice emitted on minter permission transfer
    /// @param previous Last minter address, or zero address on initialization
    /// @param current New minter address, or zero address on relinquish
    event MinterSet(address indexed previous, address indexed current);

	/// @notice supply cap
    /// @dev not `immutable` unless set in constructor, which isn't possible
    ///      so omitting functions that could write this variable will suffice.
	uint256 public maxSupply;

    /// @notice permissioned minter
    address public minter;

	/// @notice Initializes the super token only once IF it does not exceed supply cap
	/// @param _name Name of Super Token
	/// @param _symbol Symbol of Super Token
    /// @param _maxSupply Immutable max supply
    /// @param _minter Permissioned minting address
	function initialize(
		string memory _name,
		string memory _symbol,
		uint256 _maxSupply,
        address _minter
	) external {
        // underscored parameters to avoid naming collision with maxSupply and minter
		// SuperTokenBase._initialize(string,string)
		_initialize(_name, _symbol);
        maxSupply = _maxSupply;
        minter = _minter;
        emit MinterSet(address(0), _minter);
	}

	/// @notice Mints tokens to recipient if caller is the mitner AND max supply will not be exceeded
	/// @param recipient address to which the tokens are minted
	/// @param amount amount of tokens to mint
	/// @param userData optional user data for IERC777Recipient callbacks
	function mint(
		address recipient,
		uint256 amount,
		bytes memory userData
	) public {
        if (msg.sender != minter) revert OnlyMinter();
		if (_totalSupply() + amount > maxSupply) revert SupplyCapped();
        // MintableSuperToken._mint(address,uint256,bytes)
        _mint(recipient, amount, userData);
	}

	/// @notice Minter may transfer mint permissions to another address
	/// @param newMinter new minting address, or zero address if reqlinquishing minting
    function setMinter(address newMinter) public {
        address previous = minter; // gas savings
        if (msg.sender != previous) revert OnlyMinter();
        minter = newMinter;
        emit MinterSet(previous, newMinter);
    }

	function _totalSupply() internal view returns (uint256) {
		return ISuperToken(address(this)).totalSupply();
	}
}
