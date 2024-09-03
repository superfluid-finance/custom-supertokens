// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import { OPBridgedSuperTokenProxy, IOPBridgedSuperToken, IBridgedSuperToken, IOptimismMintableERC20 } from "../src/OPBridgedSuperToken.sol";
import { BridgedSuperTokenTest } from "./BridgedSuperTokenTest.t.sol";

contract OPBridgedSuperTokenTest is BridgedSuperTokenTest {
    address internal _nativeBridge = address(99);
    address internal _remoteToken = address(98);
    IOPBridgedSuperToken internal _opToken;

    function _deployToken(address owner) internal override {
        // deploy proxy
        OPBridgedSuperTokenProxy proxy = new OPBridgedSuperTokenProxy(_nativeBridge, _remoteToken);
        // initialize proxy
        proxy.initialize(sf.superTokenFactory, "Test Token", "TT", _owner, 1000);
        proxy.transferOwnership(owner);

        _opToken = IOPBridgedSuperToken(address(proxy));
        _xerc20 = IBridgedSuperToken(_opToken);
    }

    function testMintByNativeBridge(uint256 _amount) public {
        _amount = bound(_amount, 1, type(uint256).max / 2);

        vm.prank(_nativeBridge);
        _opToken.mint(_user, _amount);

        assertEq(_xerc20.balanceOf(_user), _amount);
    }

    function testBurnByNativeBridge(uint256 _amount) public {
        _amount = bound(_amount, 1, type(uint256).max / 2);

        vm.prank(_nativeBridge);
        _opToken.mint(_user, _amount);

        vm.prank(_user);
        _opToken.approve(_nativeBridge, _amount);

        vm.prank(_nativeBridge);
        _opToken.burn(_user, _amount);

        assertEq(_xerc20.balanceOf(_user), 0);
    }

    function testERC165InterfaceDetection() public view {
        assertTrue(_opToken.supportsInterface(type(IOptimismMintableERC20).interfaceId));
    }
}