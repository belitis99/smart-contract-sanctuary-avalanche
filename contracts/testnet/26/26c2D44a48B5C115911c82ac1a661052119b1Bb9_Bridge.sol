// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/bridge/IBridge.sol";

import "../handlers/ERC20Handler.sol";
import "../handlers/ERC721Handler.sol";
import "../handlers/SBTHandler.sol";
import "../handlers/ERC1155Handler.sol";
import "../handlers/NativeHandler.sol";

import "../bundle/Bundler.sol";

import "./proxy/UUPSSignableUpgradeable.sol";

import "../utils/Signers.sol";
import "../utils/Hashes.sol";

import "../libs/Encoder.sol";

contract Bridge is
    IBridge,
    UUPSSignableUpgradeable,
    Bundler,
    Signers,
    Hashes,
    ERC20Handler,
    ERC721Handler,
    SBTHandler,
    ERC1155Handler,
    NativeHandler
{
    using Encoder for *;

    function __Bridge_init(
        address signer_,
        address bundleImplementation_,
        string calldata chainName_,
        address facade_
    ) external initializer {
        __Signers_init(signer_, chainName_);
        __Bundler_init(bundleImplementation_, facade_);
    }

    function verifyMerkleLeaf(
        bytes calldata tokenDataLeaf_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_
    ) external override onlyFacade {
        bytes32 merkleLeaf_ = tokenDataLeaf_.encode(bundle_, originHash_, chainName, receiver_);

        _checkAndUpdateHashes(originHash_);
        _checkMerkleSignature(merkleLeaf_, proof_);
    }

    function changeSigner(bytes calldata newSignerPubKey_, bytes calldata signature_) external {
        _checkSignature(keccak256(newSignerPubKey_), signature_);

        signer = _convertPubKeyToAddress(newSignerPubKey_);
    }

    function changeBundleExecutorImplementation(
        address newImplementation_,
        bytes calldata signature_
    ) external {
        require(newImplementation_ != address(0), "Bridge: zero address");

        validateChangeAddressSignature(
            uint8(MethodId.ChangeBundleExecutorImplementation),
            address(this),
            newImplementation_,
            signature_
        );

        bundleExecutorImplementation = newImplementation_;
    }

    function changeFacade(address newFacade_, bytes calldata signature_) external {
        require(newFacade_ != address(0), "Bridge: zero address");

        validateChangeAddressSignature(
            uint8(MethodId.ChangeFacade),
            address(this),
            newFacade_,
            signature_
        );

        facade = newFacade_;
    }

    function _authorizeUpgrade(address) internal pure override {
        revert("Bridge: this upgrade method is off");
    }

    function _authorizeUpgrade(
        address newImplementation_,
        bytes calldata signature_
    ) internal override {
        require(newImplementation_ != address(0), "Bridge: zero address");

        validateChangeAddressSignature(
            uint8(MethodId.AuthorizeUpgrade),
            address(this),
            newImplementation_,
            signature_
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract UUPSSignableUpgradeable is UUPSUpgradeable {
    function _authorizeUpgrade(
        address newImplementation_,
        bytes calldata signature_
    ) internal virtual;

    function upgradeToWithSig(
        address newImplementation_,
        bytes calldata signature_
    ) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation_, signature_);
        _upgradeToAndCallUUPS(newImplementation_, new bytes(0), false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/bundle/IBundler.sol";

import "./proxy/BundleExecutorProxy.sol";
import "./proxy/BundleExecutorImplementation.sol";

abstract contract Bundler is IBundler, Initializable {
    address public bundleExecutorImplementation;
    address public facade;

    modifier onlyFacade() {
        _onlyFacade();
        _;
    }

    function __Bundler_init(
        address bundleExecutorImplementation_,
        address facade_
    ) public onlyInitializing {
        bundleExecutorImplementation = bundleExecutorImplementation_;
        facade = facade_;
    }

    function _bundleUp(Bundle memory bundle_) internal {
        address payable executor = payable(
            new BundleExecutorProxy{salt: bundle_.salt}(
                bundleExecutorImplementation,
                address(this)
            )
        );

        BundleExecutorImplementation(executor).execute(bundle_.bundle);
        BundleExecutorProxy(executor).destroy();
    }

    function determineProxyAddress(bytes32 salt_) public view override returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt_,
                                keccak256(
                                    abi.encodePacked(
                                        type(BundleExecutorProxy).creationCode,
                                        abi.encode(bundleExecutorImplementation, address(this))
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function _onlyFacade() private view {
        require(msg.sender == facade, "Bundler: not a facade");
    }

    uint256[48] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../../interfaces/tokens/IWrappedNative.sol";

contract BundleExecutorImplementation is ERC721Holder, ERC1155Holder {
    address public immutable WRAPPED_NATIVE;

    constructor(address wrappedNative_) {
        WRAPPED_NATIVE = wrappedNative_;
    }

    function execute(bytes calldata bundle_) external payable {
        (address[] memory contracts_, uint256[] memory values_, bytes[] memory data_) = abi.decode(
            bundle_,
            (address[], uint256[], bytes[])
        );

        require(
            contracts_.length == values_.length && values_.length == data_.length,
            "BundleExecutorImplementation: lengths mismatch"
        );
        require(contracts_.length != 0, "BundleExecutorImplementation: zero bundle");

        for (uint256 i = 0; i < contracts_.length; i++) {
            (bool success_, ) = contracts_[i].call{value: values_[i]}(data_[i]);

            require(success_, "BundleExecutorImplementation: call reverted");
        }

        if (address(this).balance > 0) {
            IWrappedNative(WRAPPED_NATIVE).deposit{value: address(this).balance}();
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BundleExecutorProxy {
    address internal immutable _IMPLEMENTATION;
    address internal immutable _BRIDGE;

    constructor(address implementation_, address bridge_) {
        _IMPLEMENTATION = implementation_;
        _BRIDGE = bridge_;
    }

    fallback() external payable {
        _delegate(_IMPLEMENTATION);
    }

    function destroy() external {
        address bridge_ = _BRIDGE;

        assembly {
            if iszero(eq(caller(), bridge_)) {
                revert(0, 0)
            }

            selfdestruct(caller())
        }
    }

    function _delegate(address implementation_) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result_ := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result_
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../interfaces/handlers/IERC1155Handler.sol";
import "../interfaces/tokens/IERC1155MintableBurnable.sol";

import "../libs/Encoder.sol";

import "../bundle/Bundler.sol";

abstract contract ERC1155Handler is IERC1155Handler, Bundler, ERC1155Holder {
    using Encoder for bytes32;

    function depositERC1155(
        DepositERC1155Parameters calldata params_
    ) external override onlyFacade {
        emit DepositedERC1155(
            params_.token,
            params_.tokenId,
            params_.amount,
            params_.bundle.salt.encode(),
            params_.bundle.bundle,
            params_.network,
            params_.receiver,
            params_.isWrapped
        );
    }

    function withdrawERC1155(WithdrawERC1155Parameters memory params_) public override onlyFacade {
        require(params_.token != address(0), "ERC1155Handler: zero token");
        require(params_.receiver != address(0), "ERC1155Handler: zero receiver");

        if (params_.isWrapped) {
            IERC1155MintableBurnable(params_.token).mintTo(
                params_.receiver,
                params_.tokenId,
                params_.amount,
                params_.tokenURI
            );
        } else {
            IERC1155MintableBurnable(params_.token).safeTransferFrom(
                address(this),
                params_.receiver,
                params_.tokenId,
                params_.amount,
                ""
            );
        }
    }

    function withdrawERC1155Bundle(
        WithdrawERC1155Parameters memory params_
    ) external override onlyFacade {
        params_.receiver = determineProxyAddress(params_.bundle.salt);

        withdrawERC1155(params_);
        _bundleUp(params_.bundle);
    }

    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/tokens/IERC20MintableBurnable.sol";
import "../interfaces/handlers/IERC20Handler.sol";

import "../libs/Encoder.sol";

import "../bundle/Bundler.sol";

abstract contract ERC20Handler is IERC20Handler, Bundler {
    using SafeERC20 for IERC20MintableBurnable;
    using Encoder for bytes32;

    function depositERC20(DepositERC20Parameters calldata params_) external override onlyFacade {
        emit DepositedERC20(
            params_.token,
            params_.amount,
            params_.bundle.salt.encode(),
            params_.bundle.bundle,
            params_.network,
            params_.receiver,
            params_.isWrapped
        );
    }

    function withdrawERC20(WithdrawERC20Parameters memory params_) public override onlyFacade {
        require(params_.token != address(0), "ERC20Handler: zero token");
        require(params_.receiver != address(0), "ERC20Handler: zero receiver");

        if (params_.isWrapped) {
            IERC20MintableBurnable(params_.token).mintTo(params_.receiver, params_.amount);
        } else {
            IERC20MintableBurnable(params_.token).safeTransfer(params_.receiver, params_.amount);
        }
    }

    function withdrawERC20Bundle(
        WithdrawERC20Parameters memory params_
    ) external override onlyFacade {
        params_.receiver = determineProxyAddress(params_.bundle.salt);

        withdrawERC20(params_);
        _bundleUp(params_.bundle);
    }

    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../interfaces/handlers/IERC721Handler.sol";
import "../interfaces/tokens/IERC721MintableBurnable.sol";
import "../interfaces/tokens/SBT/ISBT.sol";

import "../libs/Encoder.sol";

import "../bundle/Bundler.sol";

abstract contract ERC721Handler is IERC721Handler, Bundler, ERC721Holder {
    using Encoder for bytes32;

    function depositERC721(DepositERC721Parameters calldata params_) external override onlyFacade {
        emit DepositedERC721(
            params_.token,
            params_.tokenId,
            params_.bundle.salt.encode(),
            params_.bundle.bundle,
            params_.network,
            params_.receiver,
            params_.isWrapped
        );
    }

    function withdrawERC721(WithdrawERC721Parameters memory params_) public override onlyFacade {
        require(params_.token != address(0), "ERC721Handler: zero token");
        require(params_.receiver != address(0), "ERC721Handler: zero receiver");

        if (params_.isWrapped) {
            IERC721MintableBurnable(params_.token).mintTo(
                params_.receiver,
                params_.tokenId,
                params_.tokenURI
            );
        } else {
            IERC721MintableBurnable(params_.token).safeTransferFrom(
                address(this),
                params_.receiver,
                params_.tokenId
            );
        }
    }

    function withdrawERC721Bundle(
        WithdrawERC721Parameters memory params_
    ) external override onlyFacade {
        params_.receiver = determineProxyAddress(params_.bundle.salt);

        withdrawERC721(params_);
        _bundleUp(params_.bundle);
    }

    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/handlers/INativeHandler.sol";

import "../libs/Encoder.sol";

import "../bundle/Bundler.sol";

abstract contract NativeHandler is INativeHandler, Bundler {
    using Encoder for bytes32;

    function depositNative(
        DepositNativeParameters calldata params_
    ) external payable override onlyFacade {
        emit DepositedNative(
            msg.value,
            params_.bundle.salt.encode(),
            params_.bundle.bundle,
            params_.network,
            params_.receiver
        );
    }

    receive() external payable {}

    function withdrawNative(WithdrawNativeParameters memory params_) public override onlyFacade {
        require(params_.receiver != address(0), "NativeHandler: receiver is zero");

        (bool success_, ) = params_.receiver.call{value: params_.amount}("");
        require(success_, "NativeHandler: failed to send eth");
    }

    function withdrawNativeBundle(
        WithdrawNativeParameters memory params_
    ) external override onlyFacade {
        params_.receiver = determineProxyAddress(params_.bundle.salt);

        withdrawNative(params_);
        _bundleUp(params_.bundle);
    }

    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../interfaces/handlers/ISBTHandler.sol";
import "../interfaces/tokens/IERC721MintableBurnable.sol";
import "../interfaces/tokens/SBT/ISBT.sol";

import "../libs/Encoder.sol";

import "../bundle/Bundler.sol";

abstract contract SBTHandler is ISBTHandler, Bundler, ERC721Holder {
    using Encoder for bytes32;

    function depositSBT(DepositSBTParameters calldata params_) external override onlyFacade {
        emit DepositedSBT(
            params_.token,
            params_.tokenId,
            params_.bundle.salt.encode(),
            params_.bundle.bundle,
            params_.network,
            params_.receiver
        );
    }

    function withdrawSBT(WithdrawSBTParameters memory params_) public override onlyFacade {
        require(params_.token != address(0), "SBTHandler: zero token");
        require(params_.receiver != address(0), "SBTHandler: zero receiver");

        ISBT(params_.token).attestTo(params_.receiver, params_.tokenId, params_.tokenURI);
    }

    function withdrawSBTBundle(WithdrawSBTParameters memory params_) external override onlyFacade {
        params_.receiver = determineProxyAddress(params_.bundle.salt);

        withdrawSBT(params_);
        _bundleUp(params_.bundle);
    }

    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../handlers/IERC20Handler.sol";
import "../handlers/IERC721Handler.sol";
import "../handlers/ISBTHandler.sol";
import "../handlers/IERC1155Handler.sol";
import "../handlers/INativeHandler.sol";
import "../utils/ISigners.sol";

/**
 * @notice The Bridge contract
 *
 * The Bridge contract acts as a permissioned way of transferring assets (ERC20, ERC721, ERC1155, Native) between
 * 2 different blockchains.
 *
 * In order to correctly use the Bridge, one has to deploy both instances of the contract on the base chain and the
 * destination chain, as well as setup a trusted backend that will act as a `signer`.
 *
 * Each Bridge contract can either give or take the user assets when they want to transfer tokens. Both liquidity pool
 * and mint-and-burn way of transferring assets are supported.
 *
 * The bridge enables the transaction bundling feature as well.
 */
interface IBridge is
    IBundler,
    ISigners,
    IERC20Handler,
    IERC721Handler,
    ISBTHandler,
    IERC1155Handler,
    INativeHandler
{
    /**
     * @notice the enum that helps distinguish functions for calling within the signature
     * @param None the special zero type, method types start from 1
     * @param AuthorizeUpgrade the type corresponding to the _authorizeUpgrade function
     * @param ChangeBundleExecutorImplementation the type corresponding to the changeBundleExecutorImplementation function
     * @param ChangeFacade the type corresponding to the changeFacade function
     */
    enum MethodId {
        None,
        AuthorizeUpgrade,
        ChangeBundleExecutorImplementation,
        ChangeFacade
    }

    /**
     * @notice the function to verify merkle leaf
     * @param tokenDataLeaf_ the abi encoded token parameters
     * @param bundle_ the encoded transaction bundle with encoded salt
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver_ the address who will receive tokens
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    function verifyMerkleLeaf(
        bytes memory tokenDataLeaf_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBundler {
    /**
     * @notice the struct that stores bundling info
     * @param salt the salt used to determine the proxy address
     * @param bundle the encoded transaction bundle
     */
    struct Bundle {
        bytes32 salt;
        bytes bundle;
    }

    /**
     * @notice function to get the bundle executor proxy address for the given salt and bundle
     * @param salt_ the salt for create2 (origin hash)
     * @return the bundle executor proxy address
     */
    function determineProxyAddress(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC1155Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC1155 function
     */
    event DepositedERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc1155 deposit
     * @param token the address of deposited tokens
     * @param tokenId the id of deposited tokens
     * @param amount the amount of deposited tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    struct DepositERC1155Parameters {
        address token;
        uint256 tokenId;
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc1155 withdrawal
     * @param token the address of withdrawal tokens
     * @param tokenId the id of withdrawal tokens
     * @param tokenURI the uri of withdrawal tokens
     * @param amount the amount of withdrawal tokens
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC1155Parameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc1155 tokens
     * @param params_ the parameters for the erc1155 deposit
     */
    function depositERC1155(DepositERC1155Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc1155 tokens
     * @param params_ the parameters for the erc1155 withdrawal
     */
    function withdrawERC1155(WithdrawERC1155Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc1155 tokens with bundle
     * @param params_ the parameters for the erc1155 withdrawal
     */
    function withdrawERC1155Bundle(WithdrawERC1155Parameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC20Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC20 function
     */
    event DepositedERC20(
        address token,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc20 deposit
     * @param token the address of the deposited token
     * @param amount the amount of deposited tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    struct DepositERC20Parameters {
        address token;
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc20 withdrawal
     * @param token the address of the withdrawal token
     * @param amount the amount of withdrawal tokens
     * @param bundle the encoded transaction bundle with encoded salt
     * @param receiver the address who will receive tokens
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC20Parameters {
        address token;
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc20 tokens
     * @param params_ the parameters for the erc20 deposit
     */
    function depositERC20(DepositERC20Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc20 tokens
     * @param params_ the parameters for the erc20 withdrawal
     */
    function withdrawERC20(WithdrawERC20Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc20 tokens with bundle
     * @param params_ the parameters for the erc20 withdrawal
     */
    function withdrawERC20Bundle(WithdrawERC20Parameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC721Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC721 function
     */
    event DepositedERC721(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc721 deposit
     * @param token the address of the deposited token
     * @param tokenId the id of deposited token
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - token will burned, false - token will transferred
     */
    struct DepositERC721Parameters {
        address token;
        uint256 tokenId;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc721 withdrawal
     * @param token the address of the withdrawal token
     * @param tokenId the id of the withdrawal token
     * @param tokenURI the uri of the withdrawal token
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC721Parameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc721 tokens
     * @param params_ the parameters for the erc721 deposit
     */
    function depositERC721(DepositERC721Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc721 tokens
     * @param params_ the parameters for the erc721 withdrawal
     */
    function withdrawERC721(WithdrawERC721Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc721 tokens with bundle
     * @param params_ the parameters for the erc721 withdrawal
     */
    function withdrawERC721Bundle(WithdrawERC721Parameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface INativeHandler is IBundler {
    /**
     * @notice the event emitted from the depositNative function
     */
    event DepositedNative(
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice the struct that represents parameters for the native deposit
     * @param amount the amount of deposited native tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     */
    struct DepositNativeParameters {
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
    }

    /**
     * @notice the struct that represents parameters for the native withdrawal
     * @param amount the amount of withdrawal native funds
     * @param bundle the encoded transaction bundle
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    struct WithdrawNativeParameters {
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
    }

    /**
     * @notice the function to deposit native tokens
     * @param params_ the parameters for the native deposit
     */
    function depositNative(DepositNativeParameters calldata params_) external payable;

    /**
     * @notice the function to withdraw native tokens
     * @param params_ the parameters for the native withdrawal
     */
    function withdrawNative(WithdrawNativeParameters memory params_) external;

    /**
     * @notice the function to withdraw native tokens with bundle
     * @param params_ the parameters for the native withdrawal
     */
    function withdrawNativeBundle(WithdrawNativeParameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface ISBTHandler is IBundler {
    /**
     * @notice the event emitted from the depositSBT function
     */
    event DepositedSBT(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice the struct that represents parameters for the sbt deposit
     * @param token the address of deposited token
     * @param tokenId the id of deposited token
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     */
    struct DepositSBTParameters {
        address token;
        uint256 tokenId;
        IBundler.Bundle bundle;
        string network;
        string receiver;
    }

    /**
     * @notice the struct that represents parameters for the sbt withdrawal
     * @param token the address of the withdrawal token
     * @param tokenId the id of the withdrawal token
     * @param tokenURI the uri of the withdrawal token
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    struct WithdrawSBTParameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
    }

    /**
     * @notice the function to deposit sbt tokens
     * @param params_ the parameters for the sbt deposit
     */
    function depositSBT(DepositSBTParameters calldata params_) external;

    /**
     * @notice the function to withdraw sbt tokens
     * @param params_ the parameters for the sbt withdrawal
     */
    function withdrawSBT(WithdrawSBTParameters memory params_) external;

    /**
     * @notice the function to withdraw sbt tokens with bundle
     * @param params_ the parameters for the sbt withdrawal
     */
    function withdrawSBTBundle(WithdrawSBTParameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155MintableBurnable is IERC1155 {
    function mintTo(
        address receiver_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) external;

    function burnFrom(address payer_, uint256 tokenId_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
    function mintTo(address receiver_, uint256 amount_) external;

    function burnFrom(address payer_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721MintableBurnable is IERC721 {
    function mintTo(address receiver_, uint256 tokenId_, string calldata tokenURI_) external;

    function burnFrom(address payer_, uint256 tokenId_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWrappedNative is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISBT is IERC721 {
    function attestTo(address receiver_, uint256 tokenId_, string calldata tokenURI_) external;

    function burn() external;

    function tokenIdOf(address from_) external view returns (uint256 tokenId_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISigners {
    /**
     * @notice the function to check the signature and increment the nonce associated with the method selector
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @param signHash_ the sign hash to be verified
     * @param signature_ the signature to be checked
     */
    function checkSignatureAndIncrementNonce(
        uint8 methodId_,
        address contractAddress_,
        bytes32 signHash_,
        bytes calldata signature_
    ) external;

    /**
     * @notice the function to validate the address change signature
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @param newAddress_ the new signed address
     * @param signature_ the signature to be checked
     */
    function validateChangeAddressSignature(
        uint8 methodId_,
        address contractAddress_,
        address newAddress_,
        bytes calldata signature_
    ) external;

    /**
     * @notice the function to get signature components
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @return chainName_ the name of the chain
     * @return nonce_ the current nonce value associated with the method selector
     */
    function getSigComponents(
        uint8 methodId_,
        address contractAddress_
    ) external view returns (string memory chainName_, uint256 nonce_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/bridge/IBridge.sol";
import "../interfaces/bundle/IBundler.sol";

library Encoder {
    function encode(bytes32 salt_) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(salt_, tx.origin));
    }

    function encode(
        bytes calldata tokenDataLeaf_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        string memory chainName_,
        address receiver_
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    tokenDataLeaf_,
                    _getBundleLeaf(bundle_),
                    _getMetadataLeaf(originHash_, chainName_, receiver_)
                )
            );
    }

    function getTokenDataLeaf(
        IBridge.WithdrawERC20Parameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.amount);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawERC721Parameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.tokenId, params_.tokenURI);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawSBTParameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.tokenId, params_.tokenURI);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawERC1155Parameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.tokenId, params_.tokenURI, params_.amount);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawNativeParameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.amount);
    }

    function _getBundleLeaf(IBundler.Bundle calldata bundle_) private pure returns (bytes memory) {
        if (bundle_.bundle.length == 0) {
            return bytes("");
        }

        return abi.encodePacked(bundle_.salt, bundle_.bundle);
    }

    function _getMetadataLeaf(
        bytes32 originHash_,
        string memory chainName_,
        address receiver_
    ) private view returns (bytes memory) {
        return abi.encodePacked(originHash_, chainName_, receiver_, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Hashes {
    mapping(bytes32 => bool) public usedHashes; // keccak256(origin chain name . origin tx hash . event nonce) => is used

    function _checkAndUpdateHashes(bytes32 originHash_) internal {
        require(!usedHashes[originHash_], "Hashes: the hash nonce is used");

        usedHashes[originHash_] = true;
    }

    uint256[49] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/bridge/IBridge.sol";

abstract contract Signers is ISigners, Initializable {
    using ECDSA for bytes32;
    using MerkleProof for bytes32[];

    uint256 public constant P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    address public signer;
    string public chainName;

    mapping(address => mapping(uint8 => uint256)) public nonces;

    function __Signers_init(address signer_, string calldata chainName_) public onlyInitializing {
        signer = signer_;
        chainName = chainName_;
    }

    function checkSignatureAndIncrementNonce(
        uint8 methodId_,
        address contractAddress_,
        bytes32 signHash_,
        bytes calldata signature_
    ) public {
        _checkSignature(signHash_, signature_);
        ++nonces[contractAddress_][methodId_];
    }

    function validateChangeAddressSignature(
        uint8 methodId_,
        address contractAddress_,
        address newAddress_,
        bytes calldata signature_
    ) public {
        (string memory chainName_, uint256 nonce_) = getSigComponents(methodId_, contractAddress_);

        bytes32 signHash_ = keccak256(
            abi.encodePacked(methodId_, newAddress_, chainName_, nonce_, contractAddress_)
        );

        checkSignatureAndIncrementNonce(methodId_, contractAddress_, signHash_, signature_);
    }

    function getSigComponents(
        uint8 methodId_,
        address contractAddress_
    ) public view returns (string memory chainName_, uint256 nonce_) {
        return (chainName, nonces[contractAddress_][methodId_]);
    }

    function _checkSignature(bytes32 signHash_, bytes memory signature_) internal view {
        address signer_ = signHash_.recover(signature_);

        require(signer == signer_, "Signers: invalid signature");
    }

    function _checkMerkleSignature(bytes32 merkleLeaf_, bytes calldata proof_) internal view {
        (bytes32[] memory merklePath_, bytes memory signature_) = abi.decode(
            proof_,
            (bytes32[], bytes)
        );

        bytes32 merkleRoot_ = merklePath_.processProof(merkleLeaf_);

        _checkSignature(merkleRoot_, signature_);
    }

    function _convertPubKeyToAddress(bytes calldata pubKey_) internal pure returns (address) {
        require(pubKey_.length == 64, "Signers: wrong pubKey length");

        (uint256 x_, uint256 y_) = abi.decode(pubKey_, (uint256, uint256));

        // @dev y^2 = x^3 + 7, x != 0, y != 0 (mod P)
        require(x_ != 0 && y_ != 0 && x_ != P && y_ != P, "Signers: zero pubKey");
        require(
            mulmod(y_, y_, P) == addmod(mulmod(mulmod(x_, x_, P), x_, P), 7, P),
            "Signers: pubKey not on the curve"
        );

        return address(uint160(uint256(keccak256(pubKey_))));
    }

    uint256[47] private _gap;
}