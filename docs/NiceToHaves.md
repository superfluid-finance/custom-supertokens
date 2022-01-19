# Super Token Base Contracts

## Nice-To-Haves

-   Mintable
-   PreMint
-   Black-Listable
-   Pausable
-   Capped
-   Burnable

## Black-Listable

Black listing is simple on token transfers, but black listing addresses on the
super token level may require a rework to the Superfluid architecture.

Currently, calling any agreement is called from the `ISuperfluid` host contract,
which performs checks, then passes encoded calldata to an `ISuperAgreement`
contract (currently IDAv1 and CFAv1), which then encodes the agreement data and
stores it on the super token.

The interactions between agreements and super tokens are limited to a few
functions. There may be ways to extract account information on Super Tokens.
TODO Explore this.
