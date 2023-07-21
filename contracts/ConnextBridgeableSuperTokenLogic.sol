// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import { SuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import { SuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperfluidToken.sol";
import { ISuperfluid } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IConstantOutflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantOutflowNFT.sol";
import { IConstantInflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantInflowNFT.sol";

import { IConnextBridgedToken } from "./interfaces/IConnextBridgedToken.sol";

contract ConnextBridgeableSuperTokenLogic is SuperToken, IConnextBridgedToken {
    constructor(
        ISuperfluid host,
        IConstantOutflowNFT constantOutflowNFT,
        IConstantInflowNFT constantInflowNFT
    )
        SuperToken(host, constantOutflowNFT, constantInflowNFT)
    {}

    // TODO: shall we use mint/burn with or without hooks? If without, add events

    function burn(address _from, uint256 _amnt) external override {
        this.selfBurn(_from, _amnt, new bytes(0));
        //SuperfluidToken._mint(_from, _amnt);
    }

    function mint(address _to, uint256 _amnt) external {
        this.selfMint(_to, _amnt, new bytes(0));
        //SuperfluidToken._mint(_to, _amnt);
    }

    function setDetails(string calldata name_, string calldata symbol_) external override {
        _name = name_;
        _symbol = symbol_;
    }
}