// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PureSuperTokenProxy} from "../src/PureSuperToken.sol";
import {ERC1820RegistryCompiled} from "@superfluid-finance/ethereum-contracts/contracts/libs/ERC1820RegistryCompiled.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeployer.sol";
import "@superfluid-finance/ethereum-contracts/contracts/utils/SuperfluidFrameworkDeploymentSteps.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PureSuperTokenProxyTest is Test {
	PureSuperTokenProxy public pureSuperToken;
	SuperfluidFrameworkDeployer.Framework public sf;
	address public owner;

	function setUp() public {
		vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
		SuperfluidFrameworkDeployer sfDeployer = new SuperfluidFrameworkDeployer();
		sfDeployer.deployTestFramework();
		sf = sfDeployer.getFramework();
		owner = address(0x1);
	}

	function testDeploy() public {
		pureSuperToken = new PureSuperTokenProxy();
		assert(address(pureSuperToken) != address(0));
	}

	function testSuperTokenBalance() public {
		pureSuperToken = new PureSuperTokenProxy();
		pureSuperToken.initialize(
			sf.superTokenFactory,
			"TestToken",
			"TST",
			owner,
			1000
		);
		IERC20 pureSuperTokenERC20 = IERC20(address(pureSuperToken));
		uint balance = pureSuperTokenERC20.balanceOf(owner);
		assert(balance == 1000);
	}
}
