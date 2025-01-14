// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// contains information about revenue share on each sale
library LibShareholder {
    struct Shareholder {
        address account; // receiver wallet address
        uint96 value; // percentage of share
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../../libs/LibShareholder.sol";

library LibOrder {

    bytes constant orderTypeString = abi.encodePacked(
        "Order(",
        "address nftContractAddress,",
        "string salt,",
        "uint256 tokenId,",
        "uint256 price,",
        "Shareholder[] shareholders"
        ")"
    );

    bytes constant shareholderItemTypeString = abi.encodePacked(
        "Shareholder(",
        "address account,",
        "uint96 value",
        ")"
    );

    bytes32 constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(orderTypeString, shareholderItemTypeString)
    );

    bytes32 constant SHAREHOLDER_TYPEHASH = keccak256(
        shareholderItemTypeString
    );

    struct Order {
        address nftContractAddress; // nft contract address
        string salt; // uuid to provide uniquness
        uint tokenId; // nft tokenId
        uint price; // listing price
        LibShareholder.Shareholder[] shareholders; // When the nft is sold then the price will be split to the shareholders.
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        bytes32[] memory shareholderHashes = new bytes32[](order.shareholders.length);
        for (uint256 i = 0; i < order.shareholders.length; i++) {
            shareholderHashes[i] = _hashShareholderItem(order.shareholders[i]);
        }
        return keccak256(abi.encode(
                ORDER_TYPEHASH,
                order.nftContractAddress,
                keccak256(bytes(order.salt)),
                order.tokenId,
                order.price,
                keccak256(abi.encodePacked(shareholderHashes))
            ));
    }

    function _hashShareholderItem(LibShareholder.Shareholder memory shareholder) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                SHAREHOLDER_TYPEHASH,
                shareholder.account,
                shareholder.value
            ));
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(order.nftContractAddress, order.salt));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
// These functions can be used to verify that a message was signed by the holder of the private keys of a given address.
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
// is a standard for hashing and signing of typed structured data.
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../NFTCollectible/INFTCollectible.sol";
import "../PaymentManager/IPaymentManager.sol";
import "./lib/LibOrder.sol";
import "../libs/LibShareholder.sol";
/**
* @title Marketplace
* @notice allows users to make, cancel, accept and reject offers as well as purchase a listed nft using a listing coupon.
*/
contract Marketplace is Initializable, EIP712Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    struct CollectionOffer {
        uint256 amount;
        uint256 remainingAmount;
        uint256 bid;
    }

    string private constant SIGNING_DOMAIN = "Salvor";
    string private constant SIGNATURE_VERSION = "1";
    using ECDSAUpgradeable for bytes32;

    /**
    * @notice contains information about redeemed and canceled orders.
    * prevents users make transaction with the same offer on the functions.
    */
    mapping(bytes32 => bool) public fills;

    /**
    * @notice contains offered bids to the nfts that are accessible with contract_address and token_id.
    * A buyer accepts or rejects an offer, and a seller cancels or makes an offer according to this mapping.
    * e.g offers[contract_address][token_id][bidder_address] = bid;
    */
    mapping(address => mapping(uint256 => mapping(address => uint256))) public offers;

    /**
    * @notice contains total balance for each bidder_address; It used to make offers on NFTs. In order to make an offer.
    * It also provides unlimited bidding features. Bids can be made for each Nft up to the amount in the biddingWallets.
    * e.g biddingWallets[bidder_address] = total_balance;
    */
    mapping(address => uint256) public offerTotalAmounts;

    /**
    * @notice The mapping contains total bids for each bidder_address; for every bid it will be increased.
    * For every withdrawal and acceptance of an offer it will be decreased.
    * It manages whether or not to allow future withdrawal balance requests.
    * e.g offerTotalAmounts[bidder_address] = total_bid;
    */
    mapping(address => uint256) public biddingWallets;

    /**
    * @notice manages payouts for each contract.
    */
    address public paymentManager;

    /**
    * @notice a control variable to check the minimum price of the orders and offers is in the correct range.
    */
    uint256 public minimumPriceLimit;

    mapping(address => mapping(address => CollectionOffer)) public collectionOffers;


    // events
    event Fund(uint256 value);
    event Withdraw(uint256 balance, uint256 amount);
    event Cancel(address indexed collection, uint256 indexed tokenId, bytes32 hash, string salt);
    event MakeOffer(address indexed collection, uint256 indexed tokenId, uint256 amount);
    event CancelOffer(address indexed collection, uint256 indexed tokenId, bool isExternal);
    event AcceptOffer(address indexed collection, uint256 indexed tokenId, address indexed buyer, uint256 amount);
    event Redeem(address indexed collection, uint256 indexed tokenId, string salt, uint256 value);
    event RejectOffer(address indexed collection, uint256 indexed tokenId, address indexed buyer);
    event MakeCollectionOffer(address indexed collection, uint256 amount, uint256 bid);
    event CancelCollectionOffer(address indexed collection, bool isExternal);
    event AcceptCollectionOffer(address indexed collection, uint256 indexed tokenId, address indexed buyer, uint256 bid);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    function initialize(address _paymentManager) public initializer addressIsNotZero(_paymentManager) {
        __EIP712_init_unchained(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        paymentManager = _paymentManager;
        minimumPriceLimit = 10000000000000000; // 0.01 ether
    }

    /**
    * @notice Allows owner to set paymentManager contract address.
    * @param _paymentManager PaymentManager contract address.
    */
    function setPaymentManager(address _paymentManager) external onlyOwner addressIsNotZero(_paymentManager) {
        paymentManager = _paymentManager;
    }

    /**
    * @notice allows the owner to set a minimumPriceLimit that is used as a control variable
    * to check the minimum price of the orders and offers is in the correct range.
    * @param _minimumPriceLimit amount of ether
    */
    function setMinimumPriceLimit(uint256 _minimumPriceLimit) external onlyOwner {
        minimumPriceLimit = _minimumPriceLimit;
    }

    /**
    * @notice Allows to the msg.sender deposit funds to the biddingWallet balance.
    */
    function deposit() external payable whenNotPaused nonReentrant paymentAccepted {
        biddingWallets[msg.sender] += msg.value;
        emit Fund(msg.value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function batchTransfer(address[] calldata _addresses, uint256[] calldata _tokenIds, address _to) external {
        uint256 len = _addresses.length;
        require(len <= 50, "exceeded the limits");
        for (uint64 i; i < len; ++i) {
            require(IERC721Upgradeable(_addresses[i]).ownerOf(_tokenIds[i]) == msg.sender, "");
            IERC721Upgradeable(_addresses[i]).safeTransferFrom(msg.sender, _to, _tokenIds[i]);
        }
    }

    function batchCancelOffer(address[] calldata _addresses, uint256[] calldata _tokenIds) external {
        uint256 len = _addresses.length;
        require(len <= 50, "exceeded the limits");
        for (uint64 i; i < len; ++i) {
            cancelOffer(_addresses[i], _tokenIds[i]);
        }
    }

    /**
    * @notice Allows the msg.sender to make bids to any nft.
    * This can be done if the amount is less or equal to the balance in the biddingWallets.
    * @param _nftContractAddress nft contract address
    * @param _amount offer
    */
    function makeCollectionOffer(address _nftContractAddress, uint256 _amount, uint256 _bid)
    external
    whenNotPaused
    nonReentrant
    priceGreaterThanMinimumPriceLimit(_bid)
    {
        require(_amount > 0, "amount cannot be 0");
        uint256 totalOfferAmount = _amount * _bid;
        require(biddingWallets[msg.sender] >= totalOfferAmount, "Insufficient funds to make an offer");

        offerTotalAmounts[msg.sender] += totalOfferAmount;

        CollectionOffer memory collectionOffer = collectionOffers[_nftContractAddress][msg.sender];
        if (collectionOffer.remainingAmount > 0) {
            offerTotalAmounts[msg.sender] -= (collectionOffer.bid * collectionOffer.remainingAmount);
            emit CancelCollectionOffer(_nftContractAddress, false);
        }

        collectionOffer.bid = _bid;
        collectionOffer.amount = _amount;
        collectionOffer.remainingAmount = _amount;

        collectionOffers[_nftContractAddress][msg.sender] = collectionOffer;

        emit MakeCollectionOffer(_nftContractAddress, _amount, _bid);
    }

    /**
    * @notice Allows the msg.sender to cancel existing offer of own
    * @param _nftContractAddress nft contract address
    */
    function cancelCollectionOffer(address _nftContractAddress)
    external
    whenNotPaused
    nonReentrant
    {
        CollectionOffer memory collectionOffer = collectionOffers[_nftContractAddress][msg.sender];
        require(collectionOffer.remainingAmount > 0, "there is no any offer");

        uint256 totalOfferAmount = collectionOffer.remainingAmount * collectionOffer.bid;
        offerTotalAmounts[msg.sender] -= totalOfferAmount;

        collectionOffer.amount = 0;
        collectionOffer.remainingAmount = 0;
        collectionOffer.bid = 0;

        collectionOffers[_nftContractAddress][msg.sender] = collectionOffer;
        emit CancelCollectionOffer(_nftContractAddress, true);
    }

    /**
    * @notice Allows the nft owner to accept existing offers. Nft owners can share the amount via shareholders.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    * @param shareholders revenue share list
    */
    function acceptCollectionOffer(address _nftContractAddress, uint256 _tokenId, address _buyer, LibShareholder.Shareholder[] memory shareholders) external whenNotPaused nonReentrant {
        require(msg.sender != _buyer, "could not accept own offer");

        address existingNftOwner = IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId);
        require(existingNftOwner == msg.sender, "you haven't this nft");

        CollectionOffer memory collectionOffer = collectionOffers[_nftContractAddress][_buyer];

        require(collectionOffer.remainingAmount > 0, "there is no any offer for this nft");

        require(biddingWallets[_buyer] >= collectionOffer.bid, "Insufficient funds to accept an offer");

        biddingWallets[_buyer] -= collectionOffer.bid;
        offerTotalAmounts[_buyer] -= collectionOffer.bid;
        collectionOffer.remainingAmount -= 1;

        collectionOffers[_nftContractAddress][_buyer] = collectionOffer;

        emit AcceptCollectionOffer(_nftContractAddress, _tokenId, _buyer, collectionOffer.bid);

        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(msg.sender, _buyer, _tokenId);
        _payout(payable(msg.sender), _nftContractAddress, _tokenId, collectionOffer.bid, shareholders);
    }

    /**
    * @notice Allows the msg.sender to withdraw any amount from biddingWallet balance.
    * This can be done;
    *    - if msg.sender has not any ongoing offers
    *    - if msg.sender has ongoing offers then the total amount of bids of these offers is locked in offerTotalAmounts,
           in this case msg.sender can only withdraw the remaining amount from her/his locked balance.
    * @param _amount amount of ethers transferred to `msg.sender`
    */
    function withdraw(uint256 _amount) external whenNotPaused nonReentrant priceGreaterThanZero(_amount) {
        uint256 existingBalance = biddingWallets[msg.sender];
        require(existingBalance >= _amount, "Balance is insufficient for a withdrawal");
        require((existingBalance - _amount) >= offerTotalAmounts[msg.sender], "cannot withdraw the requested _amount while there are active offers");
        biddingWallets[msg.sender] -= _amount;

        payable(msg.sender).transfer(_amount);
        emit Withdraw(existingBalance, _amount);
    }

    /**
    * @notice Allows the msg.sender to make bids to any nft.
    * This can be done if the amount is less or equal to the balance in the biddingWallets.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    * @param _amount offer
    */
    function makeOffer(address _nftContractAddress, uint256 _tokenId, uint256 _amount)
    external
    whenNotPaused
    nonReentrant
    priceGreaterThanMinimumPriceLimit(_amount)
    {
        address existingNftOwner = IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId);
        require(existingNftOwner != msg.sender, "could not offer to own nft");
        require(biddingWallets[msg.sender] >= _amount, "Insufficient funds to make an offer");

        uint256 previousBid = offers[_nftContractAddress][_tokenId][msg.sender];
        if (previousBid > 0) {
            offerTotalAmounts[msg.sender] -= previousBid;
            emit CancelOffer(_nftContractAddress, _tokenId, false);
        }

        offers[_nftContractAddress][_tokenId][msg.sender] = _amount;
        offerTotalAmounts[msg.sender] += _amount;

        emit MakeOffer(_nftContractAddress, _tokenId, _amount);
    }

    /**
    * @notice Allows the msg.sender to cancel existing offer of own
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function cancelOffer(address _nftContractAddress, uint256 _tokenId)
    public
    whenNotPaused
    nonReentrant
    {
        require(offers[_nftContractAddress][_tokenId][msg.sender] > 0, "there is no any offer");

        uint256 amount = offers[_nftContractAddress][_tokenId][msg.sender];
        offers[_nftContractAddress][_tokenId][msg.sender] = 0;
        offerTotalAmounts[msg.sender] -= amount;

        emit CancelOffer(_nftContractAddress, _tokenId, true);
    }

    /**
    * @notice Allows the nft owner to accept existing offers. Nft owners can share the amount via shareholders.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    * @param shareholders revenue share list
    */
    function acceptOffer(address _nftContractAddress, uint256 _tokenId, address _buyer, LibShareholder.Shareholder[] memory shareholders) external whenNotPaused nonReentrant {
        require(msg.sender != _buyer, "could not accept own offer");

        address existingNftOwner = IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId);
        require(existingNftOwner == msg.sender, "you haven't this nft");

        require(offers[_nftContractAddress][_tokenId][_buyer] > 0, "there is no any offer for this nft");

        require(biddingWallets[_buyer] >= offers[_nftContractAddress][_tokenId][_buyer], "Insufficient funds to accept an offer");

        uint256 bid = offers[_nftContractAddress][_tokenId][_buyer];
        biddingWallets[_buyer] -= bid;
        offerTotalAmounts[_buyer] -= bid;
        offers[_nftContractAddress][_tokenId][_buyer] = 0;

        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(msg.sender, _buyer, _tokenId);
        _payout(payable(msg.sender), _nftContractAddress, _tokenId, bid, shareholders);

        emit AcceptOffer(_nftContractAddress, _tokenId, _buyer, bid);
    }

    /**
    * @notice Allows the nft owner to reject existing offers.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    * @param _buyer address to be rejected
    */
    function rejectOffer(address _nftContractAddress, uint256 _tokenId, address _buyer) external whenNotPaused nonReentrant {
        address existingNftOwner = IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId);
        require(existingNftOwner == msg.sender, "you haven't this nft");

        require(offers[_nftContractAddress][_tokenId][_buyer] > 0, "there is no any offer for this nft");

        uint256 bid = offers[_nftContractAddress][_tokenId][_buyer];
        offerTotalAmounts[_buyer] -= bid;
        offers[_nftContractAddress][_tokenId][_buyer] = 0;

        emit RejectOffer(_nftContractAddress, _tokenId, _buyer);
    }

    function batchRedeem(LibOrder.Order[] calldata orders, bytes[] calldata signatures) external payable {
        uint256 len = orders.length;
        require(len <= 20, "exceeded the limits");
        uint256 totalPrice;
        for (uint64 i; i < len; ++i) {
            totalPrice += orders[i].price;
        }
        require(msg.value >= totalPrice, "Insufficient funds to redeem");
        for (uint64 i; i < len; ++i) {
            redeem(orders[i], signatures[i]);
        }
    }

    /**
    * @notice A signature is created by a seller when the nft is listed on salvor.io.
    * If the order and signature are matched and the order has not been canceled then it can be redeemed by a buyer.
    * @param order is generated by seller as a listing coupon that contains order details
    * @param signature is generated by seller to validate order
    */
    function redeem(LibOrder.Order calldata order, bytes calldata signature)
    public
    payable
    whenNotPaused
    nonReentrant
    isNotCancelled(LibOrder.hashKey(order))
    priceGreaterThanMinimumPriceLimit(order.price)
    {
        bytes32 orderKeyHash = LibOrder.hashKey(order);
        fills[orderKeyHash] = true;
        // make sure signature is valid and get the address of the signer
        address payable signer = payable(_validate(order, signature));
        address payable sender = payable(msg.sender);

        require(sender != signer, "signer cannot redeem own coupon");

        address payable seller = signer;
        address payable buyer = sender;
        uint256 tokenId = order.tokenId;

        require(IERC721Upgradeable(order.nftContractAddress).ownerOf(tokenId) == seller, "cannot redeem the coupon, seller has not the nft");
        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= order.price, "Insufficient funds to redeem");

        IERC721Upgradeable(order.nftContractAddress).safeTransferFrom(seller, buyer, tokenId);
        if (order.price > 0) {
            _payout(seller, order.nftContractAddress, tokenId, order.price, order.shareholders);
        }
        if (msg.value > order.price) {
            buyer.transfer(msg.value - order.price);
        }
        emit Redeem(order.nftContractAddress, tokenId, order.salt, msg.value);
    }

    /**
    * @notice allows the nft owner to cancel listed nft on salvor.io.
    * Calculated hash for the requested order will stored on `fills`
    * after the cancel process order and signature cannot be used again to redeem
    * @param order is generated by seller as a listing coupon that contains order details
    * @param signature is generated by seller to validate order
    */
    function cancel(LibOrder.Order memory order, bytes memory signature)
    external
    whenNotPaused
    nonReentrant
    onlySigner(_validate(order, signature))
    isNotCancelled(LibOrder.hashKey(order))
    {
        bytes32 orderKeyHash = LibOrder.hashKey(order);
        fills[orderKeyHash] = true;

        emit Cancel(order.nftContractAddress, order.tokenId, orderKeyHash, order.salt);
    }

    function getChainId() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function balance() external view returns (uint) {
        return address(this).balance;
    }

    /**
    * @notice Process the payment for the allowed requests.
    * Process is completed in 3 steps;commission transfer, royalty transfers and revenue share transfers.
    * @param _seller receiver address
    * @param _nftContractAddress nft contract address is used for process royalty amounts
    * @param _tokenId nft tokenId  is used for process royalty amounts
    * @param _price sent amount
    * @param _shareholders price will be split to the shareholders after royalty and commission calculations.
    */
    function _payout(address payable _seller, address _nftContractAddress, uint256 _tokenId, uint256 _price, LibShareholder.Shareholder[] memory _shareholders) internal {
        IPaymentManager(paymentManager).payout{ value: _price }(_seller, _nftContractAddress, _tokenId, _shareholders, IPaymentManager(paymentManager).getCommissionPercentage());
    }

    /**
    * @notice validates order and signature are matched
    * @param order is generated by seller as a listing coupon that contains order details
    * @param signature is generated by seller to validate order
    */
    function _validate(LibOrder.Order memory order, bytes memory signature) public view returns (address) {
        bytes32 hash = LibOrder.hash(order);
        return _hashTypedDataV4(hash).recover(signature);
    }

    /**
    * @notice makes sure given price is greater than 0
    * @param _price amount in ethers
    */
    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    /**
    * @notice makes sure sent amount is greater than 0
    */
    modifier paymentAccepted() {
        require(msg.value > 0, "Bid must be grater then zero");
        _;
    }

    /**
    * @notice makes sure msg.sender is given address
    * @param _signer account address
    */
    modifier onlySigner(address _signer) {
        require(msg.sender == _signer, "Only signer");
        _;
    }

    /**
    * @notice makes sure order has not redeemed before
    * @param _orderKeyHash hash of an offer
    */
    modifier isNotCancelled(bytes32 _orderKeyHash) {
        require(!fills[_orderKeyHash], "order has already redeemed or cancelled");
        _;
    }

    /**
    * @notice checks the given value is greater than `minimumPriceLimit`
    */
    modifier priceGreaterThanMinimumPriceLimit(uint256 _price) {
        require(_price >= minimumPriceLimit, "Price must be higher than minimum price limit");
        _;
    }

    /**
    * @notice checks the given value is not zero address
    */
    modifier addressIsNotZero(address _address) {
        require(_address != address(0), "Given address must be a non-zero address");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../Royalty/LibRoyalty.sol";

interface INFTCollectible {
    function mint(string memory _tokenUri, LibRoyalty.Royalty[] memory _royalties) external returns (uint256);
    function owner() external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../libs/LibShareholder.sol";

interface IPaymentManager {
    function payout(address payable _seller, address _nftContractAddress, uint256 _tokenId, LibShareholder.Shareholder[] memory _shareholders, uint96 _commissionPercentage) external payable;
    function getMaximumShareholdersLimit() external view returns (uint256);
    function depositFailedBalance(address _account) external payable;
    function getCommissionPercentage() external returns (uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


library LibRoyalty {
    // calculated royalty
    struct Part {
        address account; // receiver address
        uint256 value; // receiver amount
    }

    // royalty information
    struct Royalty {
        address account; // receiver address
        uint96 value; // percentage of the royalty
    }
}