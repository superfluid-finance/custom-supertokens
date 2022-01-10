# Storage Layout of Custom Super Token

| slot | name                        | type                                            | contract declaration |
| ---- | --------------------------- | ----------------------------------------------- | -------------------- |
| 0    | mapping(address => uint256) | \_inactiveAgreementBitmap                       | SuperfluidToken.sol  |
| 1    | mapping(address => uint256) | \_balances                                      | SuperfluidToken.sol  |
| 2    | \_totalSupply               | uint256                                         | SuperfluidToken.sol  |
| 4    | \_reserve4                  | uint256                                         | SuperfluidToken.sol  |
| 5    | \_reserve5                  | uint256                                         | SuperfluidToken.sol  |
| 6    | \_reserve6                  | uint256                                         | SuperfluidToken.sol  |
| 7    | \_reserve7                  | uint256                                         | SuperfluidToken.sol  |
| 8    | \_reserve8                  | uint256                                         | SuperfluidToken.sol  |
| 9    | \_reserve9                  | uint256                                         | SuperfluidToken.sol  |
| 10   | \_reserve10                 | uint256                                         | SuperfluidToken.sol  |
| 11   | \_reserve11                 | uint256                                         | SuperfluidToken.sol  |
| 12   | \_reserve12                 | uint256                                         | SuperfluidToken.sol  |
| 13   | \_reserve13                 | uint256                                         | SuperfluidToken.sol  |
| 14   | \_underlyingToken           | address                                         | SuperToken.sol       |
| 15   | \_underlyingDecimals        | uint8                                           | SuperToken.sol       |
| 16   | \_name                      | string                                          | SuperToken.sol       |
| 17   | \_symbol                    | string                                          | SuperToken.sol       |
| 18   | \_allowances                | mapping(address => mapping(address => uint256)) | SuperToken.sol       |
| 19   | ???                         | ???                                             | SuperToken.sol       |
| 20   | ???                         | ???                                             | SuperToken.sol       |
| 21   | ???                         | ???                                             | SuperToken.sol       |
| 22   | \_reserve22                 | uint256                                         | SuperToken.sol       |
| 23   | \_reserve23                 | uint256                                         | SuperToken.sol       |
| 24   | \_reserve24                 | uint256                                         | SuperToken.sol       |
| 25   | \_reserve25                 | uint256                                         | SuperToken.sol       |
| 26   | \_reserve26                 | uint256                                         | SuperToken.sol       |
| 27   | \_reserve27                 | uint256                                         | SuperToken.sol       |
| 28   | \_reserve28                 | uint256                                         | SuperToken.sol       |
| 29   | \_reserve29                 | uint256                                         | SuperToken.sol       |
| 30   | \_reserve30                 | uint256                                         | SuperToken.sol       |
| 31   | \_reserve31                 | uint256                                         | SuperToken.sol       |
