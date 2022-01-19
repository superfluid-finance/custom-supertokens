// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {IERC3156FlashLender, IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156.sol";

import {SuperTokenBase} from "../base/SuperTokenBase.sol";

/// @title Flash Mintable Super Token
/// @author jtriley.eth
/// @dev Flash mint fee is not implemented here, but may be implemented on final contract.
abstract contract FlashMintSuperToken is SuperTokenBase, IERC3156FlashLender {
    /// @dev Thrown when token is not this contract
    /// @param token The invalid token address
	error InvalidToken(address token);

    /// @dev Thrown when the receiver returns a bad value
	error InvalidFlashMintReturn();

    /// @dev Required return value from receiver
	bytes32 private constant _RETURN_VALUE =
		keccak256("ERC3156FlashBorrower.onFlashLoan");

    /// @dev Returns maximum amount of tokens available for flash loan
    /// @param token Token address to loan
    /// @return Amount of tokens that can be loaned
	function maxFlashLoan(address token)
		public
		view
		override
		returns (uint256)
	{
		return token == address(this) ? _maxFlashLoan() : 0;
	}

    /// @dev Returns fee for flash loan. Defaults to 0, can be overridden
    /// @param token Token address requested
    /// @param amount Amount to be loaned
    /// @return Fee applied to given amount
	function flashFee(address token, uint256 amount)
		public
		view
		virtual
		override
		returns (uint256)
	{
		if (token != address(this)) revert InvalidToken({token: token});
		amount; // silence unused param warning
		return 0;
	}

    /// @dev Flash loan, mints amount, requires receiver to be `IERC3156FlashBorrower`,
    /// receiver must return amount + fee
    /// @param receiver Receiver of flash loan. MUST implement `IERC3156FlashBorrower`
    /// @param token Token to be flash loaned. Only `address(this)`.
    /// @param amount Amount to be loaned
    /// @param data Arbitrary data passed to the receiver
    /// @return `true` if success
	function flashLoan(
		IERC3156FlashBorrower receiver,
		address token,
		uint256 amount,
		bytes calldata data
	) public virtual override returns (bool) {
		uint256 fee = flashFee(token, amount);
		_mint(address(receiver), amount);

		if (
			receiver.onFlashLoan(msg.sender, token, amount, fee, data) !=
			_RETURN_VALUE
		) {
			revert InvalidFlashMintReturn();
		}
		ISuperToken(address(this)).selfBurn(
			address(receiver),
			amount + fee,
            new bytes(0)
		);
        return true;
	}

    /// @dev Returns max amount available (maxInt256 - totalSupply)
    /// MUST be int256 because while balances are read as uint256, internally,
    /// the max balance of a token is an int256.
    /// @return Max amount
	function _maxFlashLoan() internal view returns (uint256) {
		return
			uint256(type(int256).max) -
			ISuperToken(address(this)).totalSupply();
	}

    /// @dev Mints to receiver, calls logic contract
    /// @param receiver Mint receiver
    /// @param amount Amount to mint
	function _mint(address receiver, uint256 amount) internal {
		ISuperToken(address(this)).selfMint(receiver, amount, new bytes(0));
	}

    /// @dev Burns from sender, calls logic contract.
    /// @param sender Account from which to burn
    /// @param amount Amount to burn
	function _burn(address sender, uint256 amount) internal {
		ISuperToken(address(this)).selfBurn(sender, amount, new bytes(0));
	}
}
