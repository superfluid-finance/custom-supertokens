# Custom Super Tokens

This repository contains various implementations of custom Super Tokens, some of them experimental.

A _custom_ Super Token is a Super Token which was not deployed by the SuperTokenFactory contract.
This allows for the addition of token specific functionality which goes beyond ERC20 + Superfluid functionality.

It's recommended to implement custom Super Tokens as hybrid proxies which contain immutable custom logic and
delegate other calls to the SuperToken logic of a canonical Superfluid framework deployment, instead of duplicating that logic.  
This is also how the example contracts in this repository are implemented.

Note that all of the contained examples implement _pure_ (see [classification](https://github.com/superfluid-finance/protocol-monorepo/wiki/About-Super-Token-Classification)) Super Tokens, meaning they don't wrap any underlying ERC-20 token.
While it is also possible to implement custom Super Tokens wrapping underlying ERC20 tokens, no such example is currently included.

---

## Setup

To set up the repo for development, clone this repo and install dependencies.

```bash
git clone https://github.com/superfluid-finance/custom-supertokens
cd custom-supertokens
yarn install
```

---

## NOTICE

These contracts, while being tested internally, HAVE NOT been audited or
externally reviewed. Please use at your own risk.

## Important Notes

`SuperTokenBase` (alternatively the more minimal `SuperTokenStorage`) MUST be inherited FIRST in the final
contract, this is to ensure proper storage layout in accordance with Soldity contract inheritance rules.  
Failure to do so will likely result in corrupted storage with potentially catastrophic consequences.

Since this example contracts are implemented as hybrid proxy contracts containing only the custom functionality,
they must be _initialized_ in order to become fully functional (meaning: implement all of `ISuperToken.sol`).  
The `_initialize` function of `SuperTokenBase` takes care of that if invoked by the inheriting contract with a valid `factory` address set.  
For deployments to public networks, this address can be found in the [Superfluid console](https://console.superfluid.finance/protocol).

After (!) this initialization, you can invoke functions delegated to the canonical implementation via the proxy (e.g. `ISuperToken.selfMint`)
in one of 2 ways:
a) use the `.call` function on the custom super token's address
b) cast the custom super token's address to the`ISuperToken` interface.
For better readability, the contracts in this repo use the second option.
Here is an example of both methods calling `selfMint`:

```solidity
// using option a: address.call()
address(this).call(
    abi.encodeWithSignature(
        "selfMint(address,uint256,bytes)",
        account,
        amount,
        userData
    )
);

// using option b: ISuperToken casting
ISuperToken(address(this)).selfMint(account, amount, userData);
```

---

## Base Contracts

The `./contracts/base` directory provides a few base smart contracts to help
with development of custom functions.

### SuperTokenBase.sol

This is the base contract with nothing more than super token storage paddings, a
UUPS Proxy implementation, and a minimal `_initialize` function. Inheriting
contracts should implement their own external `initialize` function, which should
call this internal function before executing any other logic.

### SuperTokenStorage.sol

This is functionally identical to Superfluid's `CustomSuperTokenBase.sol`
abstract contract, it prevents storage slot collisions by padding slots
used/reserved by the canonical SuperToken implementation.

### UUPSProxy.sol

This is functionally similar to Superfluid's `UUPSProxy.sol` contract, with a
few minor gas optimizations.
For more details, see [EIP-1822](https://eips.ethereum.org/EIPS/eip-1822).

---

## Custom Token Contracts

These are some example custom super tokens, both to demonstrate usage of the
abstract contracts, and to test out unique super token functionality.

Reminder: This contracts are compositions of UUPSProxy with some additional logic
and become fully functional Super Tokens only if properly initialized.

### PureSuperToken.sol

_PureSuperToken_ is the most basic example for a custom Super Token.  
Its supply is immutably defined at deploy time and it contains no custom functionality.

### BurnableSuperToken.sol

The BurnableSuperToken is a burnable pure super token with the supply minted on
initialization.

### CappedSuperToken.sol

The CappedSuperToken is a mintable pure super token with an immutable maximum supply.
No tokens are minted on initialization.

### BurnMintSuperToken.sol

The BurnMintSuperToken is a burnable and mintable pure super token with role-based
permissions from Open Zeppelin's AccessControl contract. An initial supply is
minted on initialization.

### MintableSuperToken.sol

The MintableSuperToken is a mintable pure super token with owner-based permissions
from Open Zeppelin's Ownable contract. No tokens are minted on initialization.

### PureSuperTokenDeployer

The PureSuperTokenDeployer is a _factory_ contract that deploys, upgrades, and
initializes the PureSuperToken in a single transaction. This makes it easy to deploy super tokens from a UI.
