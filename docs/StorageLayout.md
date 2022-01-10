# Storage Layout of Custom Super Token

| slot | name                                   | type                                        | contract declaration | comment     |
| ---- | -------------------------------------- | ------------------------------------------- | -------------------- | ----------- |
| 0    | ???                                    | ???                                         | SuperfluidToken.sol  | always 0x01 |
| 1    | \_mapping(address => uint256)          | \_inactiveAgreementBitmap                   | SuperfluidToken.sol  | -           |
| 2    | \_mapping(address => uint256)          | uint256                                     | SuperfluidToken.sol  | -           |
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
| 18   | ???                                    | ???                                         | SuperToken.sol       | -           |
| 19   | ???                                    | ???                                         | SuperToken.sol       | -           |
| 20   | ???                                    | ???                                         | SuperToken.sol       | -           |
| 21   | ???                                    | ???                                         | SuperToken.sol       | -           |
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
