// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

/// @title Abstract Storage Contract to pad the first 32 slots of storage
/// @author Superfluid
/// @dev MUST be the FIRST contract inherited to pad the first 32 slots. The slots are padded to
/// ensure the implementation contract (SuperToken.sol) does not override any auxiliary state
/// variables. For more info see `./docs/StorageLayout.md`.
abstract contract SuperTokenStorage {
    uint256[32] internal _storagePaddings;
}
