# Custom Super Tokens

Implementations for extended super token functionality.

---

## Setup

To set up the repo for development, clone this repo and install dependencies.

```bash
git clone https://github.com/Fluid-X/CustomSuperTokens.git \
    && cd CustomSuperTokens \
    && yarn
```

---

## NOTICE

These contracts, while being tested internally, HAVE NOT been audited or
externally reviewed. Please use at your own risk.

## Important Notes

Any of the abstract super token contracts MUST be inherited FIRST in the final
contract, this is to ensure proper storage layout in accordance with Soldity
contract inheritance. Failure to inherit the base contracts first will result in
the SuperToken logic contract reading and writing unpredictable state variables
and will lead to severe bugs.

Functions exposed on `ISuperToken.sol` are not available on custom super token
contracts until _after_ the super token factory upgrades the contract. This
means acessing external functions like `selfMint` and `selfBurn` must be
accessed in one of two ways. One is to use the `.call` function on the custom
super token's address, OR cast the custom super token's address to the
`ISuperToken` interface. For readability, I have opted to use the second option,
given there are no compilation issues with solidity `^0.8.0`. Below is an
example of both methods calling `selfMint`.

```solidity
// using address.call()
address(this).call(
    abi.encodeWithSignature(
        "selfMint(address,uint256,bytes)",
        account,
        amount,
        userData
    )
);

// using ISuperToken casting
ISuperToken(address(this)).selfMint(account, amount, userData);
```

---

## Utils

The `./contracts/utils` directory provides an implementation for some required
logic and paddings used in inheriting contracts.

### SuperTokenStorage.sol

This is functionally identical to Superfluid's `CustomSuperTokenBase.sol`
abstract contract. The name was changed to SuperTokenStorage because it is more
of a storage padding base than a full super token base.

### UUPSProxy.sol

This is functionally similar to Superfluid's `UUPSProxy.sol` contract, with a
few minor gas optimizations. This is the proxy logic that allows the custom
super token contract to have `SuperToken.sol` functions available to it.

---

## Base Contracts

The `./contracts/base` directory provides a few base smart contracts to help
with development of custom, native functions.

### SuperTokenBase.sol

This is the base contract with nothing more than super token storage paddings, a
UUPS Proxy implementation, and a minimal `_initialize` function. Inheriting
contracts should implement their own external `initialize` function, which will
call this internal function before executing any other logic.

---

## Proxy Contracts

These are some example custom super tokens, both to demonstrate usage of the
abstract contracts, and to test out unique super token functionality.

### BurnableSuperToken.sol

The BurnableSuperToken is a burnable super token with the supply minted on
initialization.

### CappedSuperToken.sol

The CappedSuperToken is a mintable super token with an immutable maximum supply.
No tokens are minted on initialization.

### BurnMintSuperToken.sol

The BurnMintSuperToken is a burnable and mintable super token with role-based
permissions from Open Zeppelin's AccessControl contract. An initial supply is
minted on initialization.

### MintableSuperToken.sol

The MintableSuperToken is a mintable super token with owner-based permissions
from Open Zeppelin's Ownable contract. No tokens are minted on initialization.

### NativeSuperToken.sol

The NativeSuperToken is a minimal super token, no different from the ones
deployed from the protocol monorepo scripts. This serves as a deployable
contract via NativeSuperTokenDeployer.

### NativeSuperTokenDeployer

The NativeSuperTokenDeployer is a 'factory' contract that deploys, upgrades, and
initializes the NativeSuperToken in a single transaction. This makes it much
easier to deploy super tokens from a UI.
