// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {MintableSuperToken} from "./MintableSuperToken.sol";
import {CallHelper} from "./utils/CallHelper.sol";

contract CappedSuperToken is MintableSuperToken {
	/// @notice Thrown when supply limit would be exceeded
	error SupplyCapped();

    /// @notice immutable supply cap
	uint256 public immutable maxSupply;

	constructor(address minter_, uint256 maxSupply_)
		MintableSuperToken(minter_)
	{
		maxSupply = maxSupply_;
	}

    /// @notice Initializes the super token only once IF it does not exceed supply cap
	/// @param name super token name
	/// @param symbol super token symbol
	/// @param initialRecipient to whom the initial supply is minted
	/// @param initialSupply initially minted supply, can be zero
	/// @param userData optional user data for IERC777Recipient callbacks
	function initialize(
		string memory name,
		string memory symbol,
		address initialRecipient,
		uint256 initialSupply,
		bytes memory userData
	) external override {
        if (initialSupply > maxSupply) revert SupplyCapped();
		// ISuperToken.initialize(address,uint8,string,string);
		CallHelper._call(
			address(this),
			abi.encodeWithSelector(0x42fe0980, address(0), 18, name, symbol)
		);
		if (initialSupply > 0) {
			// ISuperToken.selfMint(address,uint256,bytes);
			CallHelper._call(
				address(this),
				abi.encodeWithSelector(
					0xc68d4283,
					initialRecipient,
					initialSupply,
					userData
				)
			);
		}
	}

	/// @notice Mints tokens to recipient if caller is the mitner AND max supply will not be exceeded
	/// @param recipient address to which the tokens are minted
	/// @param amount amount of tokens to mint
	/// @param userData optional user data for IERC777Recipient callbacks
	function mint(
		address recipient,
		uint256 amount,
		bytes memory userData
	) external override onlyMinter {
        // There has to be a better way to do this.
		uint256 totalSupply = abi.decode(
			CallHelper._staticCall(
				address(this),
				abi.encodeWithSelector(0x18160ddd)
			),
            (uint256)
		);
        if (totalSupply + amount > maxSupply) revert SupplyCapped();
		// ISuperToken.selfMint(address,uint256,bytes);
		CallHelper._call(
			address(this),
			abi.encodeWithSelector(0xc68d4283, recipient, amount, userData)
		);
	}
}
