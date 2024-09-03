// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import { IOptimismMintableERC20, IERC165 } from "./interfaces/IOptimismMintableERC20.sol";
import { BridgedSuperTokenProxy, IBridgedSuperToken, IXERC20 } from "./BridgedSuperToken.sol";

/**
 * @title Extends BridgedSuperTokenProxy with the interface required by the Optimism (Superchain) Standard Bridge
 */
contract OPBridgedSuperTokenProxy is BridgedSuperTokenProxy, IOptimismMintableERC20 {
    address internal immutable _NATIVE_BRIDGE;
    address internal immutable _REMOTE_TOKEN;

    // initializes the immutables and sets max limit for the native bridge
    constructor(address nativeBridge_, address remoteToken_) {
        _NATIVE_BRIDGE = nativeBridge_;
        _REMOTE_TOKEN = remoteToken_;
        // the native bridge gets (de facto) unlimited mint/burn allowance
        setLimits(nativeBridge_, _MAX_LIMIT, _MAX_LIMIT);
    }

    // ===== IOptimismMintableERC20 =====

    /// Returns the address of the corresponding token on the home chain
    function remoteToken() external view returns (address) {
        return _REMOTE_TOKEN;
    }

    /// Returns the address of the bridge contract
    function bridge() external view returns (address) {
        return _NATIVE_BRIDGE;
    }

    /// @inheritdoc IXERC20
    function mint(address user, uint256 amount) public override(BridgedSuperTokenProxy, IOptimismMintableERC20) {
        return super.mint(user, amount);
    }

    /// @inheritdoc IXERC20
    function burn(address user, uint256 amount) public override(BridgedSuperTokenProxy, IOptimismMintableERC20) {
        return super.burn(user, amount);
    }

    // ===== IERC165 =====

    /// ERC165 interface detection
    function supportsInterface(bytes4 interfaceId) external pure virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IOptimismMintableERC20).interfaceId;
    }
}

interface IOPBridgedSuperToken is IBridgedSuperToken, IOptimismMintableERC20 {
    function mint(address _to, uint256 _amount) external override(IXERC20, IOptimismMintableERC20);
    function burn(address _from, uint256 _amount) external override(IXERC20, IOptimismMintableERC20);
}