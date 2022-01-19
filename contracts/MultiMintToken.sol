// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {ISuperAgreement} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperAgreement.sol";
import {ISuperfluid} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Mintable Super Token that distributes from mint to IDA share holders
/// @author jtriley.eth
/// @notice Can be minted by any caller after an interval passes
contract MultiMintToken is SuperTokenBase {
	/// @notice Thrown when the time interval has not passed since the last mint
	error IntervalNotPassed();

    /// @notice Thrown when an address other than the shareIssuer issues shares
    error NotShareIssuer();

	/// @notice Minimum amount of time between mints
	uint256 public mintInterval;

	/// @notice Exact mint amount to distribute
	uint256 public mintAmount;

	/// @notice Last mint timestamp
	uint256 public lastMint;

    /// @notice Issuer of IDA shares
    address shareIssuer;

	/// @notice internal IDA address.
	/// @dev Due to compatibility issues, it is stored as address, and called as
	///      an ISuperAgreement in accorance with ISuperfluid.callAgreement
	address internal ida;

    /// @notice Index ID always 0, set as constant for readability with no additional gas cost
    uint32 internal constant _indexId = 0;

	function initialize(
		string memory _name,
		string memory _symbol,
		address _ida,
        address _shareIssuer,
		uint256 _mintInterval,
		uint256 _mintAmount
	) external {
		// underscored parameters to avoid naming collision with mintInterval and ida
		// SuperTokenBase._initialize(string,string)
		_initialize(_name, _symbol);
		ida = _ida;
        shareIssuer = _shareIssuer;
		mintInterval = _mintInterval;
		mintAmount = _mintAmount;
		lastMint = 0;

        // create the index via the ISuperfluid host
		_host().callAgreement(
			ISuperAgreement(ida),
			abi.encodeWithSignature(
				"createIndex(address,uint32,bytes)",
				address(this),
				_indexId,
				new bytes(0) // ctx
			),
			new bytes(0) // userData
		);
	}

	function mint() public {
        // check that minting interval time has passed
		if (lastMint + mintInterval > block.timestamp)
			revert IntervalNotPassed();
		
		lastMint = block.timestamp;

        // gas savings by loading from storage once
        uint256 amount = mintAmount;

        // mint tokens
        _mint(address(this), amount, "0x");

        // Distribute minted tokens
        _host().callAgreement(
            ISuperAgreement(ida),
            abi.encodeWithSignature(
                "distribute(address,uint32,uint256,bytes)",
                address(this),
                _indexId,
                amount,
                new bytes(0) // ctx
            ),
            new bytes(0) // userData
        );
	}

    function issueShare(address recipient, uint128 shares) public {
        if (msg.sender != shareIssuer) revert NotShareIssuer();

        // issue shares to recipient
        _host().callAgreement(
            ISuperAgreement(ida),
            abi.encodeWithSignature(
                "updateSubscription(address,uint32,address,uint128,bytes)",
                address(this),
                _indexId,
                recipient,
                shares,
                new bytes(0) // ctx
            ),
            new bytes(0) // userData
        );
    }

	/// @notice gets Superfluid host casted to ISuperfluid interface
	/// @notice no need to duplicate storage for this address
	/// @return host The host contract with interface
	function _host() internal view returns (ISuperfluid host) {
		return ISuperfluid(ISuperToken(address(this)).getHost());
	}
}
