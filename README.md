# Custom Super Tokens

This repository shows how to implement custom SuperTokens.

More examples coming soon.

## Setup

To set up the repo for development, start by cloning the repo

```bash
git clone https://github.com/superfluid-finance/custom-supertokens
cd custom-supertokens
```

## Installing Foundry

Make sure you have installed Foundry. If you don't have Foundry on your development environment, please refer to [Foundry Book](https://book.getfoundry.sh/).

## Install dependencies

Once Foundry has been installed, you can run the following command to install dependencies

```bash
forge install
```
This command will install the `@superfluid-finance` packages, and the `@openzeppelin-contracts (v4.9.3)` packages, in addition to to `forge-std`.

## Create your Custom Super Token

As an example of creating your own Custom Super Token, we can take a look at the `PureSuperToken.sol` contract.

```solidity
contract PureSuperTokenProxy is CustomSuperTokenBase, UUPSProxy {
	// This shall be invoked exactly once after deployment, needed for the token contract to become operational.
	function initialize(
		ISuperTokenFactory factory,
		string memory name,
		string memory symbol,
		address receiver,
		uint256 initialSupply
	) external {
		// This call to the factory invokes `UUPSProxy.initialize`, which connects the proxy to the canonical SuperToken implementation.
		// It also emits an event which facilitates discovery of this token.
		ISuperTokenFactory(factory).initializeCustomSuperToken(address(this));

		// This initializes the token storage and sets the `initialized` flag of OpenZeppelin Initializable.
		// This makes sure that it will revert if invoked more than once.
		ISuperToken(address(this)).initialize(
			IERC20(address(0)),
			18,
			name,
			symbol
		);

		// This mints the specified initial supply to the specified receiver.
		ISuperToken(address(this)).selfMint(receiver, initialSupply, "");
	}
}
```

This contract simply creates a new `UUPSProxy` which gets initialized into a Pure Super Token.
In the function `initilize`, we use the `SuperTokenFactory` contract, then we mint the full supply of the token to the `receiver`.

For more information on the creation of Custom Super Tokens, please refer to the [Technical Documentation](https://docs.superfluid.finance/docs/protocol/super-tokens/guides/deploy-super-token/deploy-custom-super-token) or the [Protocol Wiki](https://github.com/superfluid-finance/protocol-monorepo/wiki/About-Custom-Super-Token).

## Test your Custom Super Token Contract

Once you created your custom logic in the Custom Super Token Contract, you can now go ahead and write tests of your Custom Super Token.

Going back to the previous example of the Pure Super Token contract, we can see that the file including the tests of `PureSuperToken` contract is `PureSuperToken.t.sol`.

This file contains a deployment of the protocol in the method `setUp` as such:

```solidity
function setUp() public {
		vm.etch(ERC1820RegistryCompiled.at, ERC1820RegistryCompiled.bin);
		SuperfluidFrameworkDeployer sfDeployer = new SuperfluidFrameworkDeployer();
		sfDeployer.deployTestFramework();
		sf = sfDeployer.getFramework();
		owner = address(0x1);
	}
```

Then the file contains 2 tests, one of deployment and the other to check the receiver's balance

```solidity
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
```

To run these tests you can run the test command from Foundry:

```bash
forge test
```

## Deployment

There are multiple ways to manage the deployment of a Custom Super Token. One of them is using the following command line by replacing the proper arguments with your requirements:

```bash
forge create --rpc-url <RPC_URL_OF_DESIRED_CHAIN> --private-key <YOUR_PVT_KEY> --etherscan-api-key <YOUR_ETHERSCAN_API_KEY> --verify --via-ir src/PureSuperToken.sol:PureSuperTokenProxy
```

## Yul Optimization (via-ir)

Given that the testing requires the deployment of the Superfluid Protocol, the use of [Yul Optimization](https://docs.soliditylang.org/en/latest/yul.html) might be warranted.

Quoting from the [Solidity website](https://soliditylang.org/blog/2024/07/12/a-closer-look-at-via-ir/?utm_source=substack&utm_medium=email):
"via-IR is thoroughly tested and is considered to be at par in terms of security with the legacy compilation pipeline. The IR pipeline is good at running optimizations and eliminating stack too deep errors in most cases. It also generates better gas-optimized code than the default pipeline. Further optimizations are possible after stabilizing the performance. This can make the resultant EVM code more gas-efficient in the longer term."

Given the security and safety profile of "via-IR", it is considered OK to use the flag `--via-ir` during `forge test` or `forge create`.

## Learn more about Custom Super Tokens

To learn more about Custom Super Tokens, check the following resources:

- [The Custom Super Token Wiki](https://github.com/superfluid-finance/protocol-monorepo/wiki/About-Custom-Super-Token)
- 