# Storage Layout of Custom Super Token

| slot | name                                   | type                                        | contract declaration | comment     |
| ---- | -------------------------------------- | ------------------------------------------- | -------------------- | ----------- |
| 0    | ???                                    | ???                                         | ???                  | always 0x01 |
| 1    | \_inactiveAgreementBitmap              | mapping(address=>uint256)                   | SuperfluidToken.sol  | -           |
| 2    | \_balances                             | mapping(address=>uint256)                   | SuperfluidToken.sol  | -           |
| 3    | \_totalSupply                          | uint256                                     | SuperfluidToken.sol  | -           |
| 4    | \_reserve4                             | uint256                                     | SuperfluidToken.sol  | -           |
| 5    | \_reserve5                             | uint256                                     | SuperfluidToken.sol  | -           |
| 6    | \_reserve6                             | uint256                                     | SuperfluidToken.sol  | -           |
| 7    | \_reserve7                             | uint256                                     | SuperfluidToken.sol  | -           |
| 8    | \_reserve8                             | uint256                                     | SuperfluidToken.sol  | -           |
| 9    | \_reserve9                             | uint256                                     | SuperfluidToken.sol  | -           |
| 10   | \_reserve10                            | uint256                                     | SuperfluidToken.sol  | -           |
| 11   | \_reserve11                            | uint256                                     | SuperfluidToken.sol  | -           |
| 12   | \_reserve12                            | uint256                                     | SuperfluidToken.sol  | -           |
| 13   | \_reserve13                            | uint256                                     | SuperfluidToken.sol  | -           |
| 14   | \_underlyingDecimals,\_underlyingToken | uint8,address                               | SuperToken.sol       | packed      |
| 15   | \_name                                 | string                                      | SuperToken.sol       | -           |
| 16   | \_symbol                               | string                                      | SuperToken.sol       | -           |
| 17   | \_allowances                           | mapping(address=>mapping(address=>uint256)) | SuperToken.sol       | -           |
| 18   | ???                                    | ???                                         | ???                  | -           |
| 19   | ???                                    | ???                                         | ???                  | -           |
| 20   | ???                                    | ???                                         | ???                  | -           |
| 21   | ???                                    | ???                                         | ???                  | -           |
| 22   | \_reserve22                            | uint256                                     | SuperToken.sol       | -           |
| 23   | \_reserve23                            | uint256                                     | SuperToken.sol       | -           |
| 24   | \_reserve24                            | uint256                                     | SuperToken.sol       | -           |
| 25   | \_reserve25                            | uint256                                     | SuperToken.sol       | -           |
| 26   | \_reserve26                            | uint256                                     | SuperToken.sol       | -           |
| 27   | \_reserve27                            | uint256                                     | SuperToken.sol       | -           |
| 28   | \_reserve28                            | uint256                                     | SuperToken.sol       | -           |
| 29   | \_reserve29                            | uint256                                     | SuperToken.sol       | -           |
| 30   | \_reserve30                            | uint256                                     | SuperToken.sol       | -           |
| 31   | \_reserve31                            | uint256                                     | SuperToken.sol       | -           |
| 32-n | CUSTOM_SUPER_TOKEN_STORAGE_START       | -                                           | -                    | -           |

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
| 18  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 19  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 20  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
| 21  | 0x0000000000000000000000000000000000000000000000000000000000000000 | uint256                                     |
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
