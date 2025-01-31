// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperfluidFrameworkDeployer} from
    "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.t.sol";
import {ERC1820RegistryCompiled} from
    "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";
import {PureSuperTokenPermitProxy, IPureSuperTokenPermit} from "../src/PureSuperTokenPermit.sol";

contract PureSuperTokenPermitTest is Test {
    string internal constant _NAME = "TestToken";
    address internal constant _OWNER = address(0x1);
    uint256 internal constant _PERMIT_SIGNER_PK = 0xA11CE;

    address internal _permitSigner;
    IPureSuperTokenPermit internal _superTokenPermit;
    SuperfluidFrameworkDeployer.Framework internal _sf;

    function setUp() public {
        vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
        SuperfluidFrameworkDeployer sfDeployer = new SuperfluidFrameworkDeployer();
        sfDeployer.deployTestFramework();
        _sf = sfDeployer.getFramework();

        PureSuperTokenPermitProxy superTokenPermitProxy = new PureSuperTokenPermitProxy(_NAME);
        superTokenPermitProxy.initialize(_sf.superTokenFactory, _NAME, "TST", _OWNER, 1000);
        _superTokenPermit = IPureSuperTokenPermit(address(superTokenPermitProxy));

        _permitSigner = vm.addr(_PERMIT_SIGNER_PK);

        vm.prank(_OWNER);
        _superTokenPermit.transfer(_permitSigner, 500);
    }

    function testPermit(address relayer) public {
        address spender = address(0x2);
        uint256 value = 100;
        uint256 deadline = block.timestamp + 1 hours;

        uint256 nonce = _superTokenPermit.nonces(_permitSigner);

        assertEq(_superTokenPermit.allowance(_permitSigner, spender), 0, "Allowance should be 0");

        bytes32 digest = _createPermitDigest(_permitSigner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_PERMIT_SIGNER_PK, digest);

        vm.startPrank(relayer);

        // expect revert if spender doesn't match
        vm.expectRevert();
        _superTokenPermit.permit(_permitSigner, relayer, value, deadline, v, r, s);

        // expect revert if value doesn't match
        vm.expectRevert();
        _superTokenPermit.permit(_permitSigner, spender, value + 1, deadline, v, r, s);

        // expect revert if signature is invalid
        vm.expectRevert();
        _superTokenPermit.permit(_permitSigner, spender, value, deadline, v + 1, r, s);

        // expect revert if deadline is in the past
        uint256 prevBlockTS = block.timestamp;
        vm.warp(block.timestamp + deadline + 1);
        vm.expectRevert();
        _superTokenPermit.permit(_permitSigner, spender, value, deadline, v, r, s);

        // succeed with correct parameters
        vm.warp(prevBlockTS);
        _superTokenPermit.permit(_permitSigner, spender, value, deadline, v, r, s);

        vm.stopPrank();

        // Verify expected state changes
        assertEq(_superTokenPermit.nonces(_permitSigner), 1, "Nonce should be incremented");
        assertEq(_superTokenPermit.allowance(_permitSigner, spender), value, "Allowance should be set");
    }

    // ============================ Internal Functions ============================

    function _createPermitDigest(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (bytes32)
    {
        bytes32 PERMIT_TYPEHASH =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));

        bytes32 DOMAIN_SEPARATOR = _superTokenPermit.DOMAIN_SEPARATOR();

        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }
}
