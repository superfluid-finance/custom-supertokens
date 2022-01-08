// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

/// @title Helper with Super Token calls not available on the non-upgraded interface
/// @author jtirley.eth
/// @notice This is strictly to handle call validating and return data
library CallHelper {
    /// @notice Thrown when call is unsuccessful
    error CallFailed();

    /// @notice Thrown when staticcall is unsuccessful
    error StaticCallFailed();

    /// @notice Makes call to adddres with the given payload
    /// @param target Address on which to call
    /// @param payload Encoded data to call on the target address
    /// @return returnData Returns data that the address returns if successful
    function _call(address target, bytes memory payload) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call(payload);
        if (success) return returnData;
        else revert CallFailed();
    }

    /// @notice Makes staticcall (view) to address with the given payload
    /// @param target Address on which to call
    /// @param payload Encoded data to call on the target address
    /// @return returnData Returns data that the address returns if successful
    function _staticCall(address target, bytes memory payload) internal view returns (bytes memory) {
        (bool success, bytes memory returnData) = target.staticcall(payload);
        if (success) return returnData;
        else revert StaticCallFailed();
    }
}
