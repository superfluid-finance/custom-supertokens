// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

/// @title Abstract Storage Contract to pad the first 32 slots of storage
/// @author Superfluid
/// @notice MUST be the FIRST contract inherited to pad the first 32 slots.
abstract contract SuperTokenStorage {
    uint256[32] internal _storagePaddings;
}
