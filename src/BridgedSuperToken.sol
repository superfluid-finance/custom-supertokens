// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
// This abstract contract provides storage padding for the proxy
import { CustomSuperTokenBase } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/CustomSuperTokenBase.sol";
// Implementation of UUPSProxy (see https://eips.ethereum.org/EIPS/eip-1822)
import { UUPSProxy } from "@superfluid-finance/ethereum-contracts/contracts/upgradability/UUPSProxy.sol";
// Superfluid framework interfaces we need
import { ISuperToken, ISuperTokenFactory, IERC20 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IXERC20 } from "./interfaces/IXERC20.sol";

/**
 * @title The Proxy contract for a Pure SuperToken with preminted initial supply and with xERC20 support.
 */
contract BridgedSuperTokenProxy is CustomSuperTokenBase, UUPSProxy, Ownable, IXERC20 {
    /// The duration it takes for the limits to fully replenish
    uint256 internal constant _DURATION = 1 days;
    uint256 internal constant _MAX_LIMIT = type(uint256).max / 2;

    /// Maps bridge address to xERC20 bridge configurations
    mapping(address => Bridge) public bridges;

    error IXERC20_NoLockBox();
    error IXERC20_LimitsTooHigh();

    // This shall be invoked exactly once after deployment, needed for the token contract to become operational.
    function initialize(
        ISuperTokenFactory factory,
        string memory name,
        string memory symbol,
        address receiver,
        uint256 initialSupply
    ) external {
        // This call to the factory invokes `UUPSProxy.initialize`, which connects the proxy to the canonical SuperToken implementation.
        // It also emits an event which facilitates discovery of this token.
        ISuperTokenFactory(factory).initializeCustomSuperToken(address(this));

        // This initializes the token storage and sets the `initialized` flag of OpenZeppelin Initializable.
        // This makes sure that it will revert if invoked more than once.
        ISuperToken(address(this)).initialize(IERC20(address(0)), 18, name, symbol);

        // This mints the specified initial supply to the specified receiver.
        ISuperToken(address(this)).selfMint(receiver, initialSupply, "");
    }

    // ===== IXERC20 =====

    /// @inheritdoc IXERC20
    function setLockbox(address /*lockbox*/) external pure {
        // no lockbox support needed
        revert IXERC20_NoLockBox();
    }

    /// @inheritdoc IXERC20
    function setLimits(address bridge, uint256 mintingLimit, uint256 burningLimit) public onlyOwner {
        if (mintingLimit > _MAX_LIMIT || burningLimit > _MAX_LIMIT) {
            revert IXERC20_LimitsTooHigh();
        }
        _changeMinterLimit(bridge, mintingLimit);
        _changeBurnerLimit(bridge, burningLimit);
        emit BridgeLimitsSet(mintingLimit, burningLimit, bridge);
    }

    /// @inheritdoc IXERC20
    function mint(address user, uint256 amount) public virtual {
        address bridge = msg.sender;
        uint256 currentLimit = mintingCurrentLimitOf(bridge);
        if (currentLimit < amount) revert IXERC20_NotHighEnoughLimits();
        bridges[bridge].minterParams.timestamp = block.timestamp;
        bridges[bridge].minterParams.currentLimit = currentLimit - amount;
        ISuperToken(address(this)).selfMint(user, amount, "");
    }

    /// @inheritdoc IXERC20
    function burn(address user, uint256 amount) public virtual {
        address bridge = msg.sender;
        uint256 currentLimit = burningCurrentLimitOf(bridge);
        if (currentLimit < amount) revert IXERC20_NotHighEnoughLimits();
        bridges[bridge].burnerParams.timestamp = block.timestamp;
        bridges[bridge].burnerParams.currentLimit = currentLimit - amount;
        // in order to enforce user allowance limitations, we first transfer to the bridge
        // (fails if not enough allowance) and then let the bridge burn it.
        ISuperToken(address(this)).selfTransferFrom(user, bridge, bridge, amount);
        ISuperToken(address(this)).selfBurn(bridge, amount, "");
    }

    /// @inheritdoc IXERC20
    function mintingMaxLimitOf(address bridge) external view returns (uint256 limit) {
        limit = bridges[bridge].minterParams.maxLimit;
    }

    /// @inheritdoc IXERC20
    function burningMaxLimitOf(address bridge) external view returns (uint256 limit) {
        limit = bridges[bridge].burnerParams.maxLimit;
    }

    /// @inheritdoc IXERC20
    function mintingCurrentLimitOf(address bridge) public view returns (uint256 limit) {
        limit = _getCurrentLimit(
            bridges[bridge].minterParams.currentLimit,
            bridges[bridge].minterParams.maxLimit,
            bridges[bridge].minterParams.timestamp,
            bridges[bridge].minterParams.ratePerSecond
        );
    }

    /// @inheritdoc IXERC20
    function burningCurrentLimitOf(address bridge) public view returns (uint256 limit) {
        limit = _getCurrentLimit(
            bridges[bridge].burnerParams.currentLimit,
            bridges[bridge].burnerParams.maxLimit,
            bridges[bridge].burnerParams.timestamp,
            bridges[bridge].burnerParams.ratePerSecond
        );
    }

    // ===== INTERNAL FUNCTIONS =====

    function _changeMinterLimit(address bridge, uint256 limit) internal {
        uint256 oldLimit = bridges[bridge].minterParams.maxLimit;
        uint256 currentLimit = mintingCurrentLimitOf(bridge);
        bridges[bridge].minterParams.maxLimit = limit;
        bridges[bridge].minterParams.currentLimit = _calculateNewCurrentLimit(limit, oldLimit, currentLimit);
        bridges[bridge].minterParams.ratePerSecond = limit / _DURATION;
        bridges[bridge].minterParams.timestamp = block.timestamp;
    }

    function _changeBurnerLimit(address bridge, uint256 limit) internal {
        uint256 _oldLimit = bridges[bridge].burnerParams.maxLimit;
        uint256 _currentLimit = burningCurrentLimitOf(bridge);
        bridges[bridge].burnerParams.maxLimit = limit;
        bridges[bridge].burnerParams.currentLimit = _calculateNewCurrentLimit(limit, _oldLimit, _currentLimit);
        bridges[bridge].burnerParams.ratePerSecond = limit / _DURATION;
        bridges[bridge].burnerParams.timestamp = block.timestamp;
    }

    function _calculateNewCurrentLimit(uint256 limit, uint256 oldLimit, uint256 currentLimit)
        internal pure
        returns (uint256 newCurrentLimit)
    {
        uint256 difference;

        if (limit <= oldLimit) {
            difference = oldLimit - limit;
            newCurrentLimit = currentLimit > difference ? currentLimit - difference : 0;
        } else {
            difference = limit - oldLimit;
            newCurrentLimit = currentLimit + difference;
        }
    }

    function _getCurrentLimit(uint256 currentLimit, uint256 maxLimit, uint256 timestamp, uint256 ratePerSecond)
        internal view
        returns (uint256 limit)
    {
        limit = currentLimit;
        if (limit == maxLimit) {
            return limit;
        } else if (timestamp + _DURATION <= block.timestamp) {
            // the limit is fully replenished
            limit = maxLimit;
        } else if (timestamp + _DURATION > block.timestamp) {
            // the limit is partially replenished
            uint256 timePassed = block.timestamp - timestamp;
            uint256 calculatedLimit = limit + (timePassed * ratePerSecond);
            limit = calculatedLimit > maxLimit ? maxLimit : calculatedLimit;
        }
    }
}

// The token interface is just an alias of ISuperToken
// since we need no custom logic (other than for initialization) in the proxy.
interface IBridgedSuperToken is ISuperToken, IXERC20 {}