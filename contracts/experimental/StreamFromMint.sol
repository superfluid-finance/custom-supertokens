// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {ISuperfluid} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {SuperTokenBase} from "../base/SuperTokenBase.sol";

/// @title Super token that can stream from mint
/// @author jtriley.eth
/// @notice You should EXTREMELY not use this. I have no idea how this might affect solvency.
contract StreamFromMint is SuperTokenBase {
	error InvalidAddresses();

	event MintStreamUpdate(
		address indexed receiver,
		int96 flowRate,
		uint256 sum
	);

	struct MintStream {
		address receiver;
		int96 flowRate;
		uint256 lastUpdate;
		uint256 sum;
	}

	IConstantFlowAgreementV1 internal _cfa;
	MintStream internal _mintStream;

	function initialize(
		string memory name,
		string memory symbol,
		IConstantFlowAgreementV1 cfa,
		address receiver,
		int96 mintFlowRate
	) external {
		_cfa = cfa;
		_initialize(name, symbol);
		ISuperToken(address(this)).selfMint(
			address(this),
			uint256(type(int256).max),
			"0x"
		);

		_updateMintStream(receiver, mintFlowRate);
	}

	function totalSupply() external view returns (uint256) {
		(
			,
			int96 flowRate,
			uint256 lastUpdate,
			uint256 sum
		) = _getMintStreamData();

		return uint256(int256(flowRate)) * (block.timestamp - lastUpdate) + sum;
	}

	function _host() internal view returns (ISuperfluid) {
		return ISuperfluid(ISuperToken(address(this)).getHost());
	}

	function _updateMintStream(address receiver, int96 flowRate) internal {
		(
			address lastReceiver,
			int96 lastFlowRate,
			uint256 lastUpdate,
			uint256 sum
		) = _getMintStreamData();

		if (lastReceiver == address(0)) {
			if (receiver == address(0)) revert InvalidAddresses();
			// create
			_host().callAgreement(
				_cfa,
				abi.encodeWithSelector(
					_cfa.createFlow.selector,
					address(this),
					receiver,
					flowRate,
					new bytes(0)
				),
				new bytes(0)
			);
		} else if (receiver == address(0)) {
			// delete
			_host().callAgreement(
				_cfa,
				abi.encodeWithSelector(
					_cfa.deleteFlow.selector,
					address(this),
					address(this),
					lastReceiver,
					new bytes(0)
				),
				new bytes(0)
			);
		} else if (receiver == lastReceiver) {
			// update
			_host().callAgreement(
				_cfa,
				abi.encodeWithSelector(
					_cfa.updateFlow.selector,
					address(this),
					receiver,
					flowRate,
					new bytes(0)
				),
				new bytes(0)
			);
		} else {
			// delete...
			_host().callAgreement(
				_cfa,
				abi.encodeWithSelector(
					_cfa.deleteFlow.selector,
					address(this),
					address(this),
					lastReceiver,
					new bytes(0)
				),
				new bytes(0)
			);
			// then create
			_host().callAgreement(
				_cfa,
				abi.encodeWithSelector(
					_cfa.createFlow.selector,
					address(this),
					receiver,
					flowRate,
					new bytes(0)
				),
				new bytes(0)
			);
		}

		sum += uint256(int256(lastFlowRate)) * (block.timestamp - lastUpdate);

		// finally, update stream data
		_setMintStreamData(receiver, flowRate, block.timestamp, sum);
	}

	function _setMintStreamData(
		address receiver,
		int96 flowRate,
		uint256 lastUpdate,
		uint256 sum
	) internal {
        emit MintStreamUpdate(receiver, flowRate, sum);
		_mintStream = MintStream(receiver, flowRate, lastUpdate, sum);
	}

	function _getMintStreamData()
		internal
		view
		returns (
			address receiver,
			int96 flowRate,
			uint256 lastUpdate,
			uint256 sum
		)
	{
		MintStream storage ms = _mintStream;
		return (ms.receiver, ms.flowRate, ms.lastUpdate, ms.sum);
	}
}
