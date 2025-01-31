// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperfluidFrameworkDeployer} from
    "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.t.sol";
import {ERC1820RegistryCompiled} from
    "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import {PureSuperTokenProxy, IPureSuperToken} from "../src/PureSuperToken.sol";

using SuperTokenV1Library for IPureSuperToken;

contract PureSuperTokenProxyTest is Test {
    address internal constant _OWNER = address(0x1);
    uint256 internal constant _INITIAL_SUPPLY = 1000 ether;
    address internal constant _ALICE = address(0x4242);
    address internal constant _BOB = address(0x4243);

    SuperfluidFrameworkDeployer.Framework internal _sf;
    IPureSuperToken internal _superToken;

    function setUp() public {
        PureSuperTokenProxy _superTokenProxy;
        vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
        SuperfluidFrameworkDeployer sfDeployer = new SuperfluidFrameworkDeployer();
        sfDeployer.deployTestFramework();
        _sf = sfDeployer.getFramework();

        // deploy the proxy
        PureSuperTokenProxy superTokenProxy = _superTokenProxy = new PureSuperTokenProxy();
        _superTokenProxy.initialize(_sf.superTokenFactory, "TestToken", "TST", _ALICE, _INITIAL_SUPPLY);
        _superToken = IPureSuperToken(address(superTokenProxy));
    }

    function testInitialMintBalance() public {
        assert(_superToken.balanceOf(_ALICE) == _INITIAL_SUPPLY);
    }

    function testFlow() public {
        int96 flowRate = 1e12;
        uint256 duration = 3600;

        uint256 aliceInitialBalance = _superToken.balanceOf(_ALICE);
        assertEq(_superToken.balanceOf(_BOB), 0, "Bob should start with balance 0");

        vm.startPrank(_ALICE);
        _superToken.createFlow(_BOB, flowRate);
        vm.stopPrank();

        vm.warp(block.timestamp + duration);

        uint256 flowAmount = uint96(flowRate) * duration;
        assertEq(_superToken.balanceOf(_BOB), flowAmount, "Bob unexpected balance");

        vm.startPrank(_ALICE);
        _superToken.deleteFlow(_ALICE, _BOB);
        vm.stopPrank();

        assertEq(_superToken.balanceOf(_BOB), flowAmount, "Bob unexpected balance");
        assertEq(_superToken.balanceOf(_ALICE), aliceInitialBalance - flowAmount, "Alice unexpected balance");
    }
}
