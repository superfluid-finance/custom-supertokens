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

If this is inherited to omit the minting and burning functionality offered by
other contracts in this directory, then either a custom minting or burning
function should be implemented, OR the contract should self mint in the
initializer. See the above examples to call the `selfMint` function.

### BurnableMintableSuperToken.sol

This abstract contract implements internal `_mint` and `_burn` functions.

Inheriting contracts can access these internal functions directly. The contract
does not, however, make any checks for permissions or other guards for the sake
of modularity, so inheriting contracts _MUST_ perform these checks to prevent
malicious minting and burning calls.

### BurnableSuperToken.sol

This abstract contract only implements the internal `_burn` function.

Inheriting contracts can access the function directly. As above, the contract
does not perform checks, so inheriting contracts will need to do this when
calling `_burn`. Since no minting functionality is provided in this contract,
the initial supply should be minted in the initializer. See above examples to
call the `selfMint` function on initialization.

### MintableSuperToken.sol

This abstract contract only implements the internal `_mint` function.

Inheriting contracts can access the function directly. As above, the contract
does not perform checks, so inheriting contracts will need to do this when
calling `_mint`.

### SuperTokenDeployerBase.sol

This abstract contract is under development still.

The intention with this contract is to abstract away the super token creation
and upgrading by the super token factory. This contract will be inherited by
other deployer contracts, but the inheriting deployer contract should call this
function first, _THEN_ call the custom defined `initialize` function on the
Super Token. Failing to deploy, upgrade, and initialize in the same transaction
could result in front running opportunities.

If the custom `initialize` function sets any special permissions or state
variables on the custom super token contract, a front-runner could listen for
the deploy and upgrade transactions, then front-run the call to the initializer,
setting special permissions and parameters theirself. While this would likely
be noticed immediately, there may be situations where it doesn't get noticed
until a non-negligible amount of value is associated with the super token.

---

## Examples

These are some example custom super tokens, both to demonstrate usage of the
abstract contracts, and to test out unique super token functionality.

### CappedSuperToken.sol

The CappedSuperToken is a mintable super token that has a maximum supply. While
the maxSupply is technically not immutable due to constructor restrictions,
there are no functions that can overrite the maxSupply after being initialized
in this implementation.

Minting is permissioned to a single address at a time, and only the minter may
transfer minting permissions to other addresses. Ideally, this minting
permission would be controlled by an external contract with further restrictions
on minting.

Minting is checked against the total supply, meaning no more tokens can be
minted beyond the maxSupply variable.

Tests are available at `./test/CappedSuperToken.sol`.

### MultiMintToken.sol

The MultiMintToken is a different take on minting super tokens. When the super
token is initialized, it creates an InstantDistributionAgreementV1 index. Any
time tokens are minted in the future, they are immediately distributed to all
subscribers to this index.

A permissioned shareIssuer address can issue shares to any addresses. This would
ideally be an external contract with some restrictions and checks. This could be
used in the context of airdrops, where participants are issued shares in
response to arbitrary conditions being met, and any time new tokens are minted,
the share holders' balances are all updated in a single transaction.

The minting is restricted to a set interval, meaning a certain number of seconds
_MUST_ have passed before a new mint can be executed. Because of this time
restriction, any address may call mint, as no address stands to gain more from
being the one to call it.

The mint amount is also set on initialization, to insure a linear increase in
supply, though other contracts may want to implement non-linear supply
increases.

If you are familiar with how agreement calling is normally handled, you'll
notice a few differences in how agreements are called in this contract. These
calls are functionally identical to how Superfluid documents them, but this
has been altered for the sake of avoiding dependency and versioning problems
encountered with truffle and solidity `^0.8.0`.

Tests are not yet available for this token, but are being developed.
