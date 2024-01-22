// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import { FOTTokenProxy, IFOTToken } from "../../contracts/experimental/FOTToken.sol";
import { ISuperfluid } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { SuperfluidFrameworkDeployer } from "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.sol";
import { ERC1820RegistryCompiled } from "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";

contract FOTTokenTest is Test {
    IFOTToken public fotToken;
    SuperfluidFrameworkDeployer.Framework sf;
    uint256 public txFee = 1e16;

    address public admin = address(0x42);
    address public txFeeRecipient = address(0x420);
    address public alice = address(0x421);
    address public bob = address(0x422);
    address public dan = address(0x423);

    constructor() {
        vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
        SuperfluidFrameworkDeployer sfDeployer = new SuperfluidFrameworkDeployer();
        sfDeployer.deployTestFramework();
        sf = sfDeployer.getFramework();
    }

    function setUp() public {
        vm.startPrank(admin);
        FOTTokenProxy fotTokenProxy = new FOTTokenProxy(txFee, txFeeRecipient);
        fotTokenProxy.initialize(sf.superTokenFactory, "FOTToken", "FOT");
        fotToken = IFOTToken(address(fotTokenProxy));
    }

    function testTransfer() public {
        deal(address(fotToken), alice, 100 ether);

        vm.startPrank(alice);
        fotToken.transfer(bob, 1 ether);

        assertEq(fotToken.balanceOf(alice), 99 ether - txFee);
        assertEq(fotToken.balanceOf(bob), 1 ether);
        assertEq(fotToken.balanceOf(txFeeRecipient), txFee);
    }

    function testTranferFromPermissioning() public {
        deal(address(fotToken), alice, 100 ether);

        vm.startPrank(dan);
        vm.expectRevert("SuperToken: transfer amount exceeds allowance");
        fotToken.transferFrom(alice, bob, 1 ether);
        vm.stopPrank();

        // give allowance
        vm.prank(alice);
        fotToken.approve(dan, 1 ether);

        // should still fail because the fee isn't covered by the allowance
        vm.startPrank(dan);
        vm.expectRevert("SuperToken: transfer amount exceeds allowance");
        fotToken.transferFrom(alice, bob, 1 ether);
        vm.stopPrank();

        // add the fee amount
        vm.prank(alice);
        fotToken.increaseAllowance(dan, txFee);

        // now we make everybody happy
        vm.startPrank(dan);
        fotToken.transferFrom(alice, bob, 1 ether);

        assertEq(fotToken.balanceOf(alice), 99 ether - txFee);
        assertEq(fotToken.balanceOf(bob), 1 ether);
        assertEq(fotToken.balanceOf(txFeeRecipient), txFee);
    }

    function testChangeFeeConfig() external {
        // getting greedy
        uint256 newTxFee = 2e16;

        vm.startPrank(dan);
        vm.expectRevert("Ownable: caller is not the owner"); // dan isn't the owner
        // casting to payable needed because the proxy contains a payable fallback function
        fotToken.setFeeConfig(newTxFee, dan);
        vm.stopPrank();

        vm.startPrank(admin);
        fotToken.setFeeConfig(newTxFee, dan);

        deal(address(fotToken), alice, 100 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        fotToken.transfer(bob, 1 ether);

        assertEq(fotToken.balanceOf(dan), newTxFee);
    }
}