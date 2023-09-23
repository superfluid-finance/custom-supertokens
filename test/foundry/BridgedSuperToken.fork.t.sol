// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
// TODO: fix this path
import { IMintBurn, BridgedSuperToken } from "../../contracts/alternative-logic/BridgedSuperToken.sol";
import {
    ISuperfluid,
    ISuperfluidGovernance,
    ISuperToken,
    ISuperfluidToken
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IConstantOutflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantOutflowNFT.sol";
import { IConstantInflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantInflowNFT.sol";
import { UUPSProxiable } from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxiable.sol";
import { CFAv1Forwarder } from "@superfluid-finance/ethereum-contracts/contracts/utils/CFAv1Forwarder.sol";

contract BridgedSuperTokenForkTest is Test {

    address HOST_ADDR = vm.envAddress("HOST_ADDR");
    address ADMIN_ADDR = vm.envAddress("ADMIN_ADDR"); // token admin (overrides host)
    ISuperfluid host = ISuperfluid(HOST_ADDR);
    address GOV_ADDR;
    ISuperfluidGovernance gov;
    address TOKEN = vm.envAddress("TOKEN");
    ISuperToken token = ISuperToken(TOKEN);
    CFAv1Forwarder cfaFwd = CFAv1Forwarder(0xcfA132E353cB4E398080B9700609bb008eceB125);
    address constant upgradeAdmin = address(0x420);
    address constant bridgeAddr = address(0x421);
    address constant alice = address(0x690);
    address constant bob = address(0x691);

    constructor() {
        string memory rpc = vm.envString("RPC");
        vm.createSelectFork(rpc);
        console.log("token symbol: %s", token.symbol());

        GOV_ADDR = address(host.getGovernance());
        gov = ISuperfluidGovernance(host.getGovernance());
        ADMIN_ADDR = ADMIN_ADDR == address(0) ? HOST_ADDR : ADMIN_ADDR;
    }

    // HELPERS

    function deployNewLogic() public returns(address) {
        IConstantOutflowNFT cof = token.CONSTANT_OUTFLOW_NFT();
        IConstantInflowNFT cif = token.CONSTANT_INFLOW_NFT();
        BridgedSuperToken newLogic = new BridgedSuperToken(
            ISuperfluid(HOST_ADDR),
            cof,
            cif,
            upgradeAdmin,
            bridgeAddr
        );
        console.log("new logic deployed to %s", address(newLogic));
        return address(newLogic);
    }

    function smokeTestSuperToken(address superTokenAddr) public {
        ISuperToken superToken = ISuperToken(superTokenAddr);

        vm.startPrank(alice);
        deal(address(superTokenAddr), alice, uint256(100e18));

        uint256 initBal = superToken.balanceOf(address(this));

        // start a stream using the forwarder
        cfaFwd.setFlowrate(superToken, address(this), 1e9);
        skip(1000);
        assertEq(superToken.balanceOf(address(this)), initBal + 1e9 * 1000);

        // stop the stream
        cfaFwd.setFlowrate(superToken, address(this), 0);
        skip(1000);
        assertEq(superToken.balanceOf(address(this)), initBal + 1e9 * 1000); // no change

        vm.stopPrank();
    }

    // TESTS

    function testUpgrade() public {
        address newLogic = deployNewLogic();

        vm.startPrank(ADMIN_ADDR);
        UUPSProxiable(address(token)).updateCode(newLogic);
        vm.stopPrank();

        smokeTestSuperToken(TOKEN);

        address newLogic2 = deployNewLogic();
        vm.startPrank(HOST_ADDR);
        // the token is now self-sovereign
        vm.expectRevert(BridgedSuperToken.NO_PERMISSION.selector);
        UUPSProxiable(address(token)).updateCode(newLogic2);
        vm.stopPrank();

        vm.startPrank(upgradeAdmin);
        UUPSProxiable(address(token)).updateCode(newLogic2);
        vm.stopPrank();

        smokeTestSuperToken(TOKEN);
    }

    function testMintBurn() public {
        // upgrade
        address newLogic = deployNewLogic();
        vm.startPrank(ADMIN_ADDR);
        UUPSProxiable(address(token)).updateCode(newLogic);
        vm.stopPrank();

        // only the bridge can mint/burn
        vm.startPrank(alice);
        vm.expectRevert(BridgedSuperToken.NO_PERMISSION.selector);
        IMintBurn(TOKEN).mint(bob, 42e18);
        vm.expectRevert(BridgedSuperToken.NO_PERMISSION.selector);
        IMintBurn(TOKEN).burn(bob, 42e18);
        vm.stopPrank();

        // the bridge giveth
        vm.startPrank(bridgeAddr);
        IMintBurn(TOKEN).mint(bob, 42e18);
        assertEq(token.balanceOf(bob), 42e18);

        vm.startPrank(bridgeAddr);
        IMintBurn(TOKEN).mint(bob, 2e18);
        assertEq(token.balanceOf(bob), 44e18);

        // ... and the bridge taketh away
        IMintBurn(TOKEN).burn(bob, 43e18);
        assertEq(token.balanceOf(bob), 1e18);

        IMintBurn(TOKEN).burn(bob, 1e18);
        assertEq(token.balanceOf(bob), 0);

        // but nomore than there is to take
        vm.expectRevert(ISuperfluidToken.SF_TOKEN_BURN_INSUFFICIENT_BALANCE.selector);
        IMintBurn(TOKEN).burn(bob, 1e18);
        vm.stopPrank();
    }
}