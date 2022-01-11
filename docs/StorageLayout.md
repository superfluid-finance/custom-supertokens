# Storage Layout of Custom Super Token

| slot | name                                   | type                                        | contract declaration | comment   |
| ---- | -------------------------------------- | ------------------------------------------- | -------------------- | --------- |
| 0    | \_initializing,\_initialized           | bool,bool                                   | Initializable        | init      |
| 1    | \_inactiveAgreementBitmap              | mapping(address=>uint256)                   | SuperfluidToken      | -         |
| 2    | \_balances                             | mapping(address=>uint256)                   | SuperfluidToken      | -         |
| 3    | \_totalSupply                          | uint256                                     | SuperfluidToken      | -         |
| 4    | \_reserve4                             | uint256                                     | SuperfluidToken      | -         |
| 5    | \_reserve5                             | uint256                                     | SuperfluidToken      | -         |
| 6    | \_reserve6                             | uint256                                     | SuperfluidToken      | -         |
| 7    | \_reserve7                             | uint256                                     | SuperfluidToken      | -         |
| 8    | \_reserve8                             | uint256                                     | SuperfluidToken      | -         |
| 9    | \_reserve9                             | uint256                                     | SuperfluidToken      | -         |
| 10   | \_reserve10                            | uint256                                     | SuperfluidToken      | -         |
| 11   | \_reserve11                            | uint256                                     | SuperfluidToken      | -         |
| 12   | \_reserve12                            | uint256                                     | SuperfluidToken      | -         |
| 13   | \_reserve13                            | uint256                                     | SuperfluidToken      | -         |
| 14   | \_underlyingDecimals,\_underlyingToken | uint8,address                               | SuperToken           | packed    |
| 15   | \_name                                 | string                                      | SuperToken           | -         |
| 16   | \_symbol                               | string                                      | SuperToken           | -         |
| 17   | \_allowances                           | mapping(address=>mapping(address=>uint256)) | SuperToken           | -         |
| 18   | \_operators.defaultOperatorsArray      | address[]                                   | SuperToken           | Operators |
| 19   | \_operators.defaultOperators           | mapping(address=>bool)                      | SuperToken           | Operators |
| 20   | \_operators.operators                  | mapping(address=>mapping(address=>bool))    | SuperToken           | Operators |
| 21   | \_operators.revokeDefaultOperators     | mapping(address=>mapping(address=>bool))    | SuperToken           | Operators |
| 22   | \_reserve22                            | uint256                                     | SuperToken           | -         |
| 23   | \_reserve23                            | uint256                                     | SuperToken           | -         |
| 24   | \_reserve24                            | uint256                                     | SuperToken           | -         |
| 25   | \_reserve25                            | uint256                                     | SuperToken           | -         |
| 26   | \_reserve26                            | uint256                                     | SuperToken           | -         |
| 27   | \_reserve27                            | uint256                                     | SuperToken           | -         |
| 28   | \_reserve28                            | uint256                                     | SuperToken           | -         |
| 29   | \_reserve29                            | uint256                                     | SuperToken           | -         |
| 30   | \_reserve30                            | uint256                                     | SuperToken           | -         |
| 31   | \_reserve31                            | uint256                                     | SuperToken           | -         |
| 32-n | ProxyStorageStart                      | -                                           | -                    | -         |

### Init

The OpenZeppelin `Initializable.sol` contract defines two private boolean state
variables, `_initializing` and `_initialized`. Since booleans are stored as
`uint8` values, meaning the EVM will pack them into the same storage slot.

While loading slot zero returns:
`0x0000000000000000000000000000000000000000000000000000000000000001`,
the storage is actually just `0x 00 01` where the rightmost byte is the value of
`_initialized` (true) while the next byte to the left is the value of
`_initializing` (false).

### Packed

The `uint8 _underlyingDecimals` and `address _underlyingToken` state variables
are packed into a single storage slot.

### Operators

The `Operators` struct is defined in the ERC777Helper and is assigned to slots
18 to 21 in `SuperToken.sol`. The struct is defined as follows.

```solidity
struct Operators {
	address[] defaultOperatorsArray;
	mapping(address => bool) defaultOperators;
	mapping(address => mapping(address => bool)) operators;
	mapping(address => mapping(address => bool)) revokedDefaultOperators;
}
```

---

## MATIC Mainnet Example

Result of padded storage slot iteration on Super USDC (PoS) query on MATIC.

Reproducable with Javascript:

```js
let key = 0

while (key < 32) {
	const value = await web3.eth.getStorageAt(
		"0xcaa7349cea390f89641fe306d93591f87595dc1f",
		key
	)
	console.log(`key: ${key}\tvalue: ${value}`)
	++key
}
```

_NOTE:_ Mapping storage slots will be a zero value since each key's value is
stored at `keccak256(abi.encode(key, slotNumber))`.

| key | value                                                              | type (above)                                |
| --- | ------------------------------------------------------------------ | ------------------------------------------- |
| 0   | 0x0000000000000000000000000000000000000000000000000000000000000001 | uint256                                     |
| 1   | 0x0000000000000000000000000000000000000000000000000000000000000000 | mapping(address=>uint256)                   |
| 2   | 0x0000000000000000000000000000000000000000000000000000000000000000 | mapping(address=>uint256)                   |
| 3   | 0x00000000000000000000000000000000000000000000c2d625fe5f65f465f000 | uint256                                     |
| 4   | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 5   | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 6   | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 7   | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 8   | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 9   | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 10  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 11  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 12  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 13  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 14  | 0x0000000000000000000000062791bca1f2de4661ed88a30c99a7a9449aa84174 | uint8,address                               |
| 15  | 0x537570657220555344432028506f532900000000000000000000000000000020 | string                                      |
| 16  | 0x555344437800000000000000000000000000000000000000000000000000000a | string                                      |
| 17  | 0x0000000000000000000000000000000000000000000000000000000000000000 | mapping(address=>mapping(address=>uint256)) |
| 18  | 0x0000000000000000000000000000000000000000000000000000000000000000 | address[]                                   |
| 19  | 0x0000000000000000000000000000000000000000000000000000000000000000 | mapping(address=>bool)                      |
| 20  | 0x0000000000000000000000000000000000000000000000000000000000000000 | mapping(address=>mapping(address=>bool))    |
| 21  | 0x0000000000000000000000000000000000000000000000000000000000000000 | mapping(address=>mapping(address=>bool))    |
| 22  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 23  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 24  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 25  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 26  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 27  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 28  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 29  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 30  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 31  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
