// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PureSuperTokenProxy} from "../src/PureSuperToken.sol";
import {ERC1820RegistryCompiled} from "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.sol";
import "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeploymentSteps.sol";

contract PureSuperTokenProxyTest is Test {
	PureSuperTokenProxy public pureSuperToken;
	SuperfluidFrameworkDeployer.Framework public sf;
	address public owner;

	function setUp() public {
		vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
		SuperfluidFrameworkDeployer sfDeployer = new SuperfluidFrameworkDeployer();
		sfDeployer.deployTestFramework();
		sf = sfDeployer.getFramework();
		owner = address(this);
	}

	function testDeploy() public {
		pureSuperToken = new PureSuperTokenProxy();
		assertTrue(address(deployedContract) != address(0));
	}

	function testSuperTokenBalance(uint256 x) public {
		pureSuperToken = new PureSuperTokenProxy();
		pureSuperToken.initialize(
			sf.superTokenFactory,
			"TestToken",
			"TST",
			owner,
			1000
		);
		uint balance = pureSuperToken.balanceOf(owner);
		assertTrue(balance == 1000);
	}
}
