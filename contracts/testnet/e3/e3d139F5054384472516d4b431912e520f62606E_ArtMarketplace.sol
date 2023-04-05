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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../Royalty/IRoyalty.sol";
import "../Royalty/LibRoyalty.sol";
import "../NFTCollectible/INFTCollectible.sol";
import "../PaymentManager/IPaymentManager.sol";
import "../libs/LibShareholder.sol";

/**
* @title ArtMarketplace
* @notice the users can simply list and lock their NFTs for a specific period and earn rewards if it does not sell.
*/
contract ArtMarketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721HolderUpgradeable, PausableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Node {
        // holds the index of the next node in the linked list.
        uint256 tokenId;
        // variable holds the listing price of the NFT
        uint256 price;
        // holds the index of the previous node in the linked list.
        uint64 previousIndex;
        // holds the index of the next node in the linked list.
        uint64 nextIndex;
        // set to true when the NFT is deposited, otherwise it will be false, it determines that NFT is available to buy or not.
        bool isActive;
    }

    struct Order {
        // holds the wallet address of the seller who listed the NFT.
        address seller;
        // holds the timestamp indicating when the NFT was listed.
        uint256 startedAt;
        // holds the listing price of the NFT
        uint256 price;
        // holds the duration for which NFTs will be locked.
        uint256 lockDuration;
        // holds the percentage of commission taken from every sale.
        uint96 commissionPercentage;
        // holds the pointer for matched node
        uint64 nodeIndex;
        /**
        * There is a restriction about removing arrays defined in a struct.
        * This value helps to iterate and remove every shareholder value.
        */
        uint8 shareholderSize;
        // set to true when the NFT is deposited, otherwise it will be false and it determines that users will not receive the reward
        bool isRewardable;
    }

    struct UserInfo {
        // holds the total number of NFTs for the user that are eligible for rewards in the pool.
        uint256 rewardableNFTCount;
        // The amount of ART entitled to the user.
        uint256 rewardDebt;
        // the balance that the user has failed to collect as rewards.
        uint256 failedBalance;
    }

    struct PoolInfo {
        // represents the rate at which rewards are generated for the pool.
        uint256 rewardGenerationRate;
        // represents the total amount of art accumulated per share.
        uint256 accARTPerShare;
        // holds the timestamp of the last reward that was generated for the pool.
        uint256 lastRewardTimestamp;
        // holds the total number of NFTs that are eligible for rewards in the pool.
        uint256 totalRewardableNFTCount;
        // holds the initial floor price of NFTs
        uint256 initialFloorPrice;
        // holds the duration for which NFTs will be locked.
        uint256 lockDuration;
        // holds the minimum number of nodes that need to be active for the floor price to be increased.
        uint256 floorPriceThresholdNodeCount;
        // holds the index of the node responsible for updating the floor price of NFTs when the number of deposited nodes exceeds the specified number in "floorPriceThresholdNodeCount".
        // This information is used to determine the current floor price of NFTs.
        uint256 activeNodeCount;
         // holds the percentage by which the floor price of the NFTs will increase.
        uint96 floorPriceIncreasePercentage;
        // holds the percentage of commission taken from every sale.
        uint96 commissionPercentage;
        // holds the index of the node responsible for restricting the floor price.
        uint64 floorPriceNodeIndex;
    }

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Address of ART contract.
    IERC20Upgradeable public art;

    /**
	* @notice manages payouts for each contract.
    */
    address public paymentManager;

    // mapping of address to PoolInfo structure to store information of all liquidity pools.
    mapping(address => PoolInfo) public pools;

    // an array of Node structs, which holds information about each node in the pool.   
    mapping(address => Node[]) public nodes;

    // holds information about each user in the pool
    mapping(address => mapping(address => UserInfo)) public users;

    // the NFTs listed for trade in a specific pool.
    mapping(address => mapping(uint256 => Order)) public listedNFTs;

    // mapping of uint8 to LibShareholder.Shareholder structs, which holds information about each shareholder in the NFT.
    mapping(address => mapping(uint256 => mapping(uint8 => LibShareholder.Shareholder))) public shareholders;

    // Set of all LP tokens that have been added as pools
    EnumerableSetUpgradeable.AddressSet private lpCollections;

    // By using a factor such as ACC_TOKEN_PRECISION, accARTPerShare is stored in a highly accurate manner.
    // This factor is present to reduce loss from division operations. 
    uint256 private constant ACC_TOKEN_PRECISION = 1e18;

    event Add(address indexed lpAddress, uint256 rewardGenerationRate, uint256 initialFloorPrice);
    event Deposit(address indexed user, address indexed lpAddress, uint256 tokenId, uint256 price);
    event Withdraw(address indexed user, address indexed lpAddress, uint256 tokenId);
    event Buy(address indexed user, address indexed lpAddress, uint256 tokenId, uint256 price);
    event UpdatePool(address indexed lpAddress, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accARTPerShare);
    event Harvest(address indexed user, address indexed lpAddress, uint256 amount, bool isStandalone);
    event EndRewardPeriod(address indexed lpAddress, uint256 tokenId);
    event ReAdjustNFT(address indexed lpAddress, uint256 tokenId);
    event PaymentManagerSet(address indexed paymentManager);
    event PoolInfoUpdated(
        address indexed lpAddress,
        uint256 rewardGenerationRate,
        uint256 initialFloorPrice,
        uint256 floorPriceThresholdNodeCount,
        uint256 lockDuration,
        uint96 floorPriceIncreasePercentage,
        uint96 commissionPercentage
    );

    /**
	* @notice checks the given value is not zero address
    */
    modifier addressIsNotZero(address _address) {
        require(_address != address(0), "Given address must be a non-zero address");
        _;
    }

    /**
	* @notice makes sure price is greater than 0
    */
    modifier priceAccepted(uint256 _price) {
        require(_price > 0, "Price must be grater then zero");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IERC20Upgradeable _art, address _paymentManager)
        public
        initializer
        addressIsNotZero(_paymentManager)
        addressIsNotZero(address(_art)) {

        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC721Holder_init_unchained();
        art = _art;
        paymentManager = _paymentManager;
        emit PaymentManagerSet(_paymentManager);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
	* @notice allows owner to set paymentManager contract address.
    * @param _paymentManager PaymentManager contract address.
    */
    function setPaymentManager(address _paymentManager) external onlyOwner addressIsNotZero(_paymentManager) {
        paymentManager = _paymentManager;
        emit PaymentManagerSet(_paymentManager);
    }

    /**
	* @notice allows owner to update the pool info. 
    * @param _lpAddress the address of the liquidity pool
    * @param _rewardGenerationRate the reward generation rate of the liquidity pool
    * @param _initialFloorPrice the initial floor price of the liquidity pool
    * @param _floorPriceThresholdNodeCount the threshold limit used to determine the actual calculated floor price when the deposited NFT count surpasses the threshold value.
    * @param _lockDuration the lock duration of NFTs in the liquidity pool
    * @param _floorPriceIncreasePercentage the percentage increase of the floor price
    * @param _commissionPercentage the percentage of the transaction fee
    */
    function updatePoolInfo(
        address _lpAddress,
        uint256 _rewardGenerationRate,
        uint256 _initialFloorPrice,
        uint256 _floorPriceThresholdNodeCount,
        uint256 _lockDuration,
        uint96 _floorPriceIncreasePercentage,
        uint96 _commissionPercentage
    ) external onlyOwner {
        require(lpCollections.contains(_lpAddress), "The provided liquidity pool does not exist");
        _updatePool(_lpAddress);
        PoolInfo memory pool = pools[_lpAddress];
        pool.rewardGenerationRate = _rewardGenerationRate;
        pool.initialFloorPrice = _initialFloorPrice;
        pool.floorPriceThresholdNodeCount = _floorPriceThresholdNodeCount;
        pool.lockDuration = _lockDuration;
        pool.floorPriceIncreasePercentage = _floorPriceIncreasePercentage;
        pool.commissionPercentage = _commissionPercentage;
        pools[_lpAddress] = pool;
        emit PoolInfoUpdated(
            _lpAddress,
            _rewardGenerationRate,
            _initialFloorPrice,
            _floorPriceThresholdNodeCount,
            _lockDuration,
            _floorPriceIncreasePercentage,
            _commissionPercentage
        );
    }


    /**
	* @notice used to collect (or "harvest") the rewards that have been generated for a specific user in a specific liquidity pool
    * @param _lpAddress the address of the liquidity pool
    * @param _receiver the address of the receiver
    */
    function harvest(address _lpAddress, address _receiver) external addressIsNotZero(_lpAddress) addressIsNotZero(_receiver) {
        _updatePool(_lpAddress);
        UserInfo memory user = users[_lpAddress][_receiver];
        uint256 accArtPerShare = pools[_lpAddress].accARTPerShare;
        uint256 previousRewardDebt = user.rewardDebt;
        users[_lpAddress][_receiver].rewardDebt = (user.rewardableNFTCount * accArtPerShare) / ACC_TOKEN_PRECISION;
        uint256 pending = ((user.rewardableNFTCount * accArtPerShare) / ACC_TOKEN_PRECISION) - previousRewardDebt;

        if (pending > 0 || user.failedBalance > 0) {
            emit Harvest(_receiver, _lpAddress, pending, true);
            _safeTransfer(_lpAddress, _receiver, pending);
        }
    }

    /**
    * @notice returns an array of Node structs, which holds information about each node in the pool.
    * It retrieves the relevant information about the nodes from storage by returning the 'nodes' variable from the 'pools[_lpAddress]' struct.
    * Additionally this function helps to calculate the position of the new node to be added to the pool in the linked list by providing all the nodes already listed in the pool.
    * @param _lpAddress the address of the liquidity pool
    */
    function listNodes(address _lpAddress) external view returns (Node[] memory) {
        return nodes[_lpAddress];
    }

    /**
    * @notice returns a specific Node struct from the pool, based on the provided index
    * @param _lpAddress the address of the liquidity pool
    * @param _index the index of the Node
    */
    function getNode(address _lpAddress, uint64 _index) external view returns (Node memory) {
        return nodes[_lpAddress][_index];
    }

    /**
    * @notice returns the UserInfo struct of a specific user in a specific liquidity pool
    * @param _lpAddress the address of the liquidity pool
    * @param _user the address of the user
    */
    function getUser(address _lpAddress, address _user) external view returns (UserInfo memory) {
        return users[_lpAddress][_user];
    }

    /**
    * @notice allows the owner to add a new liquidity pool to the contract.
    * @param _lpAddress the address of the liquidity pool
    * @param _generationRate the reward generation rate
    * @param _initialFloorPrice the initial floor price
    * @param _floorPriceThresholdNodeCount the threshold limit used to determine the actual calculated floor price when the deposited NFT count surpasses the threshold value.
    * @param _floorPriceIncreasePercentage the floor price increase percentage
    * @param _lockDuration the lock duration
    * @param _commissionPercentage the commission percentage
    */
    function addPool(
        address _lpAddress,
        uint256 _generationRate,
        uint256 _initialFloorPrice,
        uint256 _floorPriceThresholdNodeCount,
        uint96 _floorPriceIncreasePercentage,
        uint256 _lockDuration,
        uint96 _commissionPercentage
    ) external onlyOwner {
        require(!lpCollections.contains(_lpAddress), "add: LP already added");
        require(_commissionPercentage < 2000, "commission percentage cannot be higher than 20%");
        // check to ensure _lpCollection is an ERC721 address
        require(IERC721Upgradeable(_lpAddress).supportsInterface(_INTERFACE_ID_ERC721), "only erc721 is supported");

        pools[_lpAddress] = PoolInfo({
            rewardGenerationRate: _generationRate,
            lastRewardTimestamp: block.timestamp,
            initialFloorPrice: _initialFloorPrice,
            floorPriceIncreasePercentage: _floorPriceIncreasePercentage,
            lockDuration: _lockDuration,
            commissionPercentage: _commissionPercentage,
            floorPriceThresholdNodeCount: _floorPriceThresholdNodeCount,
            accARTPerShare: 0,
            totalRewardableNFTCount: 0,
            floorPriceNodeIndex: 0,
            activeNodeCount: 0
        });

        lpCollections.add(_lpAddress);
        emit Add(_lpAddress, _generationRate, _initialFloorPrice);
    }

    /**
    * @notice calculates and returns the pending rewards for a specific user in a specific liquidity pool.
    * @param _lpAddress the address of the liquidity pool
    * @param _user the address of the user
    */
    function pendingRewards(address _lpAddress, address _user) external view returns (uint256) {
        PoolInfo memory pool = pools[_lpAddress];
        UserInfo memory user = users[_lpAddress][_user];
        uint256 accARTPerShare = pool.accARTPerShare;
        if (block.timestamp > pool.lastRewardTimestamp && pool.totalRewardableNFTCount > 0) {
            uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;
            uint256 artReward = secondsElapsed * pool.rewardGenerationRate;
            accARTPerShare = accARTPerShare + ((artReward * ACC_TOKEN_PRECISION) / pool.totalRewardableNFTCount);
        }
        return ((user.rewardableNFTCount * accARTPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
    }

    /**
    * @notice If the requirements are met, this function ends the reward period of multiple NFTs at once. Be cautious of gas spending!
    * @param _lpAddresses an array of addresses of liquidity pools
    * @param _tokenIds an array of token ids
    */
    function massEndRewardPeriod(address[] calldata _lpAddresses, uint256[] calldata _tokenIds) external whenNotPaused {
        uint256 len = _lpAddresses.length;
        for (uint256 i; i < len; ++i) {
            endRewardPeriod(_lpAddresses[i], _tokenIds[i]);
        }
    }

    /**
    * @notice allows the owner of a listed NFT to withdraw it from the specified liquidity pool.
    * @param _lpAddress liquidity pool address
    * @param _tokenId NFT's tokenId
    */
    function withdrawNFT(address _lpAddress, uint256 _tokenId) external whenNotPaused nonReentrant {
        Order memory listedNFT = listedNFTs[_lpAddress][_tokenId];
        require(listedNFT.seller == msg.sender, "The sender is not the owner of the listed NFT and cannot withdraw it.");
        require((block.timestamp - listedNFT.startedAt) > listedNFT.lockDuration, "The minimum lock duration has not expired.");
        _withdrawNFT(_lpAddress, _tokenId);
    }

    /**
	* @notice Allows the owner to emergency withdraw a listed NFT from the specified LP pool by providing the LP address and NFT ID.
    * The NFT will be withdrawn only if it was previously listed for sale by a seller.
    * This function should be used in case of emergencies only.
    * @param _lpAddress The address of the LP pool from which to withdraw the NFT.
    * @param _tokenId The ID of the NFT to withdraw.
    */
    function emergencyWithdrawNFT(address _lpAddress, uint256 _tokenId) external onlyOwner {
        Order memory listedNFT = listedNFTs[_lpAddress][_tokenId];
        require(listedNFT.seller != address(0x0), "The NFT is not currently listed for sale");
        _withdrawNFT(_lpAddress, _tokenId);
    }

    function depositNFTs(
        address[] calldata _lpAddresses,
        uint256[] calldata _tokenIds,
        uint256 _price,
        uint64[] calldata _freeIndexes,
        uint64 _previousIndex,
        LibShareholder.Shareholder[] memory _shareholders
    ) external {
        uint256 len = _lpAddresses.length;
        require(len <= 20, "exceeded the limits");
        for (uint64 i; i < len; ++i) {
            uint64 previousIndex = i == 0 ? _previousIndex : _freeIndexes[i - 1];
            depositNFT(_lpAddresses[i], _tokenIds[i], _price, _freeIndexes[i], previousIndex, _shareholders);
        }
    }

    function buyNFTs(address[] calldata _lpAddresses, uint256[] calldata _tokenIds) external payable {
        uint256 len = _lpAddresses.length;
        require(len <= 20, "exceeded the limits");
        for (uint64 i; i < len; ++i) {
            buyNFT(_lpAddresses[i], _tokenIds[i]);
        }
    }

    function reAdjustNFTs(
        address _lpAddress,
        uint256[] calldata _tokenIds,
        uint256 _price,
        uint64 _previousIndex
    ) external whenNotPaused nonReentrant {
        require(lpCollections.contains(_lpAddress), "The provided liquidity pool does not exist");
        uint256 totalReadjustedItemCount = _tokenIds.length;
        require(totalReadjustedItemCount <= 20, "exceeded the limits");
        for (uint64 i; i < totalReadjustedItemCount; ++i) {
            uint256 _tokenId = _tokenIds[i];
            require(listedNFTs[_lpAddress][_tokenId].seller == msg.sender, "Only the owner of the listed NFT can re-adjust it");
            require(!listedNFTs[_lpAddress][_tokenId].isRewardable, "A rewardable NFT cannot be re-adjusted");

            _dropNode(_lpAddress, _tokenId);
        }
        for (uint64 i; i < totalReadjustedItemCount; ++i) {
            uint64 _calculatedPreviousIndex = i == 0 ? _previousIndex : listedNFTs[_lpAddress][_tokenIds[i-1]].nodeIndex;
            uint256 _tokenId = _tokenIds[i];

            uint256 floorPrice = pools[_lpAddress].initialFloorPrice;
            if (pools[_lpAddress].activeNodeCount > 0 && nodes[_lpAddress][pools[_lpAddress].floorPriceNodeIndex].price < floorPrice) {
                floorPrice = nodes[_lpAddress][pools[_lpAddress].floorPriceNodeIndex].price;
            }
            uint256 allowableMaxPrice = (floorPrice * (10000 + pools[_lpAddress].floorPriceIncreasePercentage)) / 10000;
            require(_price <= allowableMaxPrice, "The provided price exceeds the allowable maximum price for this liquidity pool");
            uint64 freeIndex = listedNFTs[_lpAddress][_tokenId].nodeIndex;
            listedNFTs[_lpAddress][_tokenId].isRewardable = true;
            listedNFTs[_lpAddress][_tokenId].startedAt = block.timestamp;
            listedNFTs[_lpAddress][_tokenId].price = _price;
            _addNode(_lpAddress, _tokenId, _price, freeIndex, _calculatedPreviousIndex);

            emit ReAdjustNFT(_lpAddress, _tokenId);
        }

        _updatePool(_lpAddress);
        uint256 pending;
        if (users[_lpAddress][msg.sender].rewardableNFTCount > 0) {
            pending = ((users[_lpAddress][msg.sender].rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION) - users[_lpAddress][msg.sender].rewardDebt;
            if (pending > 0) {
                emit Harvest(msg.sender, _lpAddress, pending, false);
            }
        }


        users[_lpAddress][msg.sender].rewardableNFTCount += totalReadjustedItemCount;
        users[_lpAddress][msg.sender].rewardDebt = (users[_lpAddress][msg.sender].rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION;

        pools[_lpAddress].totalRewardableNFTCount += totalReadjustedItemCount;

        if (pending > 0) {
            _safeTransfer(_lpAddress, msg.sender, pending);
        }
    }

    /**
    * @notice allows a user to buy a listed NFT from a specified liquidity pool.
    * @param _lpAddress liquidity pool address
    * @param _tokenId NFT's tokenId
    */
    function buyNFT(address _lpAddress, uint256 _tokenId) public payable nonReentrant whenNotPaused {
        Order memory listedNFT = listedNFTs[_lpAddress][_tokenId];
        require(listedNFT.seller != address(0x0), "The NFT with this token ID is not currently listed on this liquidity pool.");
        require(listedNFT.seller != msg.sender, "Cannot buy your own NFT");
        require(msg.value >= listedNFT.price, "Incorrect payment amount");

        PoolInfo memory pool = pools[_lpAddress];
        UserInfo memory user = users[_lpAddress][listedNFT.seller];

        _dropNode(_lpAddress, _tokenId);

        emit Buy(msg.sender, _lpAddress, _tokenId, listedNFT.price);

        _updatePool(_lpAddress);
        uint256 pending;
        if (user.rewardableNFTCount > 0) {
            pending = ((user.rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
            if (pending > 0) {
                emit Harvest(listedNFT.seller, _lpAddress, pending, false);
            }
        }

        if (listedNFT.isRewardable) {
            user.rewardableNFTCount -= 1;
            pools[_lpAddress].totalRewardableNFTCount = pool.totalRewardableNFTCount - 1;
        }
        users[_lpAddress][listedNFT.seller].rewardDebt = (user.rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION;
        users[_lpAddress][listedNFT.seller].rewardableNFTCount = user.rewardableNFTCount;

        LibShareholder.Shareholder[] memory _shareholders = _getShareholders(_lpAddress, _tokenId);
        _resetListedNFT(_lpAddress, _tokenId, listedNFTs[_lpAddress][_tokenId].shareholderSize);

        IERC721Upgradeable(_lpAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

        IPaymentManager(paymentManager).payout{ value: listedNFT.price }(
            payable(listedNFT.seller),
            _lpAddress,
            _tokenId,
            _shareholders,
            listedNFT.commissionPercentage
        );

        if (pending > 0) {
            _safeTransfer(_lpAddress, listedNFT.seller, pending);
        }
    }


    /**
    * @notice allows a user to deposit an NFT token to a specific liquidity pool.
    * _freeIndex and _previousIndex help to keep track of the node position in the doubly linked list, for example, to know which node is the next or previous one, or to know the order of the nodes.
    * The floor price is used to prevent the listing of NFTs at excessively high prices.
    * The floor price is determined by taking the price of the node at a specific index in the doubly linked list, which is determined by the number of nodes in the pool and a threshold value provided during the creation of the pool.
    * The function checks if the provided price is less than or equal to the floor price. If the provided price is higher it throws an error message, preventing the user from listing an NFT at an excessively high price.
    * It is also worth noting that floor price is also protected by a percentage increase value that is set during the pool creation, this means that the floor price can't be exceeded by more than the value of the percentage increase.
    * @param _lpAddress the address of the liquidity pool
    * @param _tokenId the token ID of the NFT
    * @param _price the price at which the NFT will be listed
    * @param _freeIndex is the index of the next available node in the 'nodes' array, where the new node will be added.
    * @param _previousIndex is the index of the node that comes before the new node in the list. This allows for easy traversal of the nodes in the list and maintaining the order of the nodes.
    * @param _shareholders an array of Shareholder structs representing the shareholders of the token
    */
    function depositNFT(
        address _lpAddress,
        uint256 _tokenId,
        uint256 _price,
        uint64 _freeIndex,
        uint64 _previousIndex,
        LibShareholder.Shareholder[] memory _shareholders
    ) public priceAccepted(_price) whenNotPaused nonReentrant {
        require(lpCollections.contains(_lpAddress), "The provided liquidity pool does not exist");

        Order memory listedNFT = listedNFTs[_lpAddress][_tokenId];

        require(listedNFT.seller == address(0), "The provided NFT has already been listed on this pool");
        require(IERC721Upgradeable(_lpAddress).ownerOf(_tokenId) == msg.sender, "The provided NFT does not belong to the sender");

        PoolInfo memory pool = pools[_lpAddress];
        UserInfo memory user = users[_lpAddress][msg.sender];

        uint256 floorPrice = pool.initialFloorPrice;
        if (pool.activeNodeCount > 0 && nodes[_lpAddress][pool.floorPriceNodeIndex].price < floorPrice) {
            floorPrice = nodes[_lpAddress][pool.floorPriceNodeIndex].price;
        }
        uint256 allowableMaxPrice = (floorPrice * (10000 + pool.floorPriceIncreasePercentage)) / 10000;
        require(_price <= allowableMaxPrice, "The provided price exceeds the allowable maximum price for this liquidity pool");

        _addNode(_lpAddress, _tokenId, _price, _freeIndex, _previousIndex);

        _updatePool(_lpAddress);
        uint256 pending;
        if (user.rewardableNFTCount > 0) {
            pending = ((user.rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION);
            pending -= user.rewardDebt;
            if (pending > 0) {
                emit Harvest(msg.sender, _lpAddress, pending, false);
            }
        }

        emit Deposit(msg.sender, _lpAddress, _tokenId, _price);

        listedNFTs[_lpAddress][_tokenId] = Order({
            seller: msg.sender,
            price: _price,
            startedAt: block.timestamp,
            isRewardable: true,
            nodeIndex: _freeIndex,
            commissionPercentage: pool.commissionPercentage,
            lockDuration: pool.lockDuration,
            shareholderSize: 0
        });

        _setShareholders(_lpAddress, _tokenId, _shareholders);

        user.rewardableNFTCount += 1;
        users[_lpAddress][msg.sender].rewardDebt = (user.rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION;
        users[_lpAddress][msg.sender].rewardableNFTCount = user.rewardableNFTCount;

        pools[_lpAddress].totalRewardableNFTCount = pool.totalRewardableNFTCount + 1;

        IERC721Upgradeable(_lpAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        if (pending > 0) {
            _safeTransfer(_lpAddress, msg.sender, pending);
        }
    }

    /**
    * @notice Ends the reward period for a specific NFT token in a specific liquidity pool.
    * @param _lpAddress liquidity pool address
    * @param _tokenId NFT's tokenId
    */
    function endRewardPeriod(address _lpAddress, uint256 _tokenId) public whenNotPaused {
        require(lpCollections.contains(_lpAddress), "The provided liquidity pool does not exist");

        Order memory listedNFT = listedNFTs[_lpAddress][_tokenId];
        require(listedNFT.seller != address(0), "The NFT with this token ID is not currently listed on this liquidity pool.");
        require(listedNFT.isRewardable, "The reward period for this NFT has already ended.");

        PoolInfo memory pool = pools[_lpAddress];
        require((block.timestamp - listedNFT.startedAt) > listedNFT.lockDuration, "The minimum lock duration has not expired.");

        UserInfo memory user = users[_lpAddress][listedNFT.seller];

        emit EndRewardPeriod(_lpAddress, _tokenId);

        _updatePool(_lpAddress);
        uint256 pending;
        if (user.rewardableNFTCount > 0) {
            pending = ((user.rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
            if (pending > 0) {
                emit Harvest(listedNFT.seller, _lpAddress, pending, false);
            }
        }

        user.rewardableNFTCount -= 1; 
        users[_lpAddress][listedNFT.seller].rewardDebt = (user.rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION;
        users[_lpAddress][listedNFT.seller].rewardableNFTCount = user.rewardableNFTCount;

        pools[_lpAddress].totalRewardableNFTCount = pool.totalRewardableNFTCount - 1;
        listedNFTs[_lpAddress][_tokenId].isRewardable = false;
        if (pending > 0) {
            _safeTransfer(_lpAddress, listedNFT.seller, pending);
        }
    }

    /**
    * @notice withdraws a listed NFT from the specified liquidity pool.
    * @param _lpAddress liquidity pool address
    * @param _tokenId NFT's tokenId
    */
    function _withdrawNFT(address _lpAddress, uint256 _tokenId) internal {
        Order memory listedNFT = listedNFTs[_lpAddress][_tokenId];

        UserInfo memory user = users[_lpAddress][listedNFT.seller];
        _updatePool(_lpAddress);
        uint256 pending;
        if (user.rewardableNFTCount > 0) {
            pending = ((user.rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
            if (pending > 0) {
                emit Harvest(listedNFT.seller, _lpAddress, pending, false);
            }
        }

        _dropNode(_lpAddress, _tokenId);
        emit Withdraw(listedNFT.seller, _lpAddress, _tokenId);

        if (listedNFT.isRewardable) {
            users[_lpAddress][listedNFT.seller].rewardableNFTCount = user.rewardableNFTCount - 1;
            pools[_lpAddress].totalRewardableNFTCount -= 1;
        }
        users[_lpAddress][listedNFT.seller].rewardDebt = (users[_lpAddress][listedNFT.seller].rewardableNFTCount * pools[_lpAddress].accARTPerShare) / ACC_TOKEN_PRECISION;

        _resetListedNFT(_lpAddress, _tokenId, listedNFT.shareholderSize);

        IERC721Upgradeable(_lpAddress).safeTransferFrom(address(this), listedNFT.seller, _tokenId);

        if (pending > 0) {
            _safeTransfer(_lpAddress, listedNFT.seller, pending);
        }
    }

    /**
    * @notice Add a new node to the linked list of nodes that represent the prices of NFTs in a specific liquidity pool.
    * _freeIndex and _previousIndex help to keep track of the node position in the doubly linked list, for example, to know which node is the next or previous one, or to know the order of the nodes.
    * The floor price is used to prevent the listing of NFTs at excessively high prices.
    * The floor price is determined by taking the price of the node at a specific index in the doubly linked list
    * If the provided price is higher it throws an error message, preventing the user from listing an NFT at an excessively high price.
    * @param _lpAddress the address of the liquidity pool.
    * @param _tokenId the token ID of the NFT.
    * @param _price the price of the NFT.
    * @param _freeIndex is checked to make sure it is pointing to a valid location in the list and that there are no reusable nodes available.
    * @param _previousIndex the index of the node that the new node should come before in the list.
    */
    function _addNode(address _lpAddress, uint256 _tokenId, uint256 _price, uint64 _freeIndex, uint64 _previousIndex) internal {
        PoolInfo memory pool = pools[_lpAddress];
        bool doesFreeIndexPointReusableNode = _freeIndex < nodes[_lpAddress].length && !nodes[_lpAddress][_freeIndex].isActive;
        bool isReusableNodeExisting = (nodes[_lpAddress].length - pool.activeNodeCount) > 0;

        if (!doesFreeIndexPointReusableNode) {
            // _freeIndex must point last index of nodes as a new node
            require(_freeIndex == nodes[_lpAddress].length, "freeIndex is out of range");
            require(!isReusableNodeExisting, "Reusable node available, please use the existing node.");
        }

        /*
            If the activeNodeCount value is 0, the node will definitely be added to the beginning of the linked list and added as the node that determines the floor price.
            It will be added as the first node in the list and used as a reference point for the floor price, unless a previously used node is available to be reused in the list.
        */
        if (pool.activeNodeCount == 0) {
            _registerNewNode(
                doesFreeIndexPointReusableNode,
                _lpAddress,
                _tokenId,
                _price,
                _freeIndex,
                _freeIndex,
                _freeIndex
            );
            pools[_lpAddress].floorPriceNodeIndex = _freeIndex;
        } else {
            /*
                When _previousIndex is equal to _freeIndex, it means that the new node is being added to the head of the list and its price must be lower than the next node's price.
                The new node is added as the head of the list and its next index is set to the current head of the list
                If the `_previousIndex` is not the same as the `freeIndex` it means that the new node is being added somewhere in between other nodes, and the previous and next nodes' indices are updated to include the new node.
                The new node is added either as a reusable node or as a new node in the list.
            */
            if (_previousIndex == _freeIndex) {
                Node memory nextNode = nodes[_lpAddress][pool.floorPriceNodeIndex];
                require(nextNode.price > _price, "price must be lower than next node price");
                uint64 nextIndex = pool.floorPriceNodeIndex;
                _registerNewNode(
                    doesFreeIndexPointReusableNode,
                    _lpAddress,
                    _tokenId,
                    _price,
                    _freeIndex,
                    _freeIndex,
                    nextIndex
                );
                nextNode.previousIndex = _freeIndex;
                nodes[_lpAddress][pool.floorPriceNodeIndex] = nextNode;
                pools[_lpAddress].floorPriceNodeIndex = _freeIndex;
            } else {
                Node memory previousNode = nodes[_lpAddress][_previousIndex];
                require(previousNode.isActive, "previous node is must be active");
                require(previousNode.price <= _price, "price must be higher than previous node price");
                uint64 nextIndex = _freeIndex;
                if (previousNode.nextIndex != _previousIndex) {
                    Node memory nextNode = nodes[_lpAddress][previousNode.nextIndex];
                    require(previousNode.price <= _price && _price <= nextNode.price, "price must be higher than previous node and must be lower than next node");
                    nextNode.previousIndex = _freeIndex;
                    nodes[_lpAddress][previousNode.nextIndex] = nextNode;
                    nextIndex = previousNode.nextIndex;
                }
                previousNode.nextIndex = _freeIndex;
                nodes[_lpAddress][_previousIndex] = previousNode;

                _registerNewNode(
                    doesFreeIndexPointReusableNode,
                    _lpAddress,
                    _tokenId,
                    _price,
                    _freeIndex,
                    _previousIndex,
                    nextIndex
                );
            } 
        }
        pools[_lpAddress].activeNodeCount = pool.activeNodeCount + 1;
    }


    /**
    * @notice Registers a new node in the linked list for the specified liquidity pool.
    * If a free node already exists, it will reuse it and update its information,
    * otherwise a new node will be created and added to the end of the linked list.
    * @param _doesFreeIndexPointReusableNode A boolean indicating whether there is a free node that can be reused.
    * @param _lpAddress The address of the liquidity pool.
    * @param _tokenId the token ID of the NFT.
    * @param _price The price of the NFT.
    * @param _freeIndex The index of the free node to be reused (if exists).
    * @param _previousIndex The index of the previous node in the linked list.
    * @param _nextIndex The index of the next node in the linked list.
    */
    function _registerNewNode(
        bool _doesFreeIndexPointReusableNode,
        address _lpAddress,
        uint256 _tokenId,
        uint256 _price,
        uint64 _freeIndex,
        uint64 _previousIndex,
        uint64 _nextIndex
    ) internal {
        Node memory newNode = Node({
            price: _price,
            previousIndex: _previousIndex,
            nextIndex: _nextIndex,
            tokenId: _tokenId,
            isActive: true
        });
        if (_doesFreeIndexPointReusableNode) {
            nodes[_lpAddress][_freeIndex] = newNode;
        } else {
            nodes[_lpAddress].push(newNode);
        }
    }

    /**
    * @notice Responsible for removing a specific node from the linked list of nodes in the specified liquidity pool.
    * It updates the previous, next, and current node references in the linked list.
    * If the node is also the floor price node, the next node in the list will be set as the new floor price node.
    * @param _lpAddress the address of the liquidity pool.
    * @param _tokenId the token ID of the NFT.
    */
    function _dropNode(address _lpAddress, uint256 _tokenId) internal {
        uint64 nodeIndex = listedNFTs[_lpAddress][_tokenId].nodeIndex;

        Node memory currentNode = nodes[_lpAddress][nodeIndex];
        Node storage previousNode = nodes[_lpAddress][currentNode.previousIndex];
        Node storage nextNode = nodes[_lpAddress][currentNode.nextIndex];

        if (nodeIndex == currentNode.previousIndex) {
            nextNode.previousIndex = currentNode.nextIndex;
            pools[_lpAddress].floorPriceNodeIndex = currentNode.nextIndex;
        } else if (nodeIndex == currentNode.nextIndex) {
            previousNode.nextIndex = currentNode.previousIndex;
        } else {
            previousNode.nextIndex = currentNode.nextIndex;
            nextNode.previousIndex = currentNode.previousIndex;
        }

        delete nodes[_lpAddress][nodeIndex];
        pools[_lpAddress].activeNodeCount -= 1;
    }

    /**
    * @notice Updates the accARTPerShare and lastRewardTimestamp value, which is used to calculate the rewards users will earn when they harvest in the future.
    * @param _lpAddress The address of the pool. See `poolInfo`.
    */
    function _updatePool(address _lpAddress) internal {
        PoolInfo memory pool = pools[_lpAddress];
        if (block.timestamp > pool.lastRewardTimestamp) {
            if (pool.totalRewardableNFTCount > 0) {
                uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;
                uint256 artReward = secondsElapsed * pool.rewardGenerationRate;
                pools[_lpAddress].accARTPerShare = pool.accARTPerShare + ((artReward * ACC_TOKEN_PRECISION) / pool.totalRewardableNFTCount);
            }
            pools[_lpAddress].lastRewardTimestamp = block.timestamp;
            emit UpdatePool(_lpAddress, pool.lastRewardTimestamp, pool.totalRewardableNFTCount, pool.accARTPerShare);
        }
    }

    /**
    * @notice retrieves the shareholders of a specific NFT in a specific liquidity pool.
    * @param _lpAddress liquidity pool address
    * @param _tokenId NFT's tokenId
    */
    function _getShareholders(address _lpAddress, uint256 _tokenId) internal view returns (LibShareholder.Shareholder[] memory) {
        uint256 shareholderSize = listedNFTs[_lpAddress][_tokenId].shareholderSize;
        LibShareholder.Shareholder[] memory _shareholders = new LibShareholder.Shareholder[](shareholderSize);
        for (uint8 i; i < shareholderSize; i++) {
            _shareholders[i] = shareholders[_lpAddress][_tokenId][i];
        }
        return _shareholders;
    }

    /**
    * @notice set the shareholders for a specific NFT token in a specific liquidity pool.
    * @param _lpAddress liquidity pool address
    * @param _tokenId NFT's tokenId
    * @param _shareholders an array of Shareholder structs representing the shareholders of the token
    */
    function _setShareholders(address _lpAddress, uint256 _tokenId, LibShareholder.Shareholder[] memory _shareholders) internal {
        uint256 shareholderSize = _shareholders.length;
        // makes sure shareholders does not exceed the limits defined in PaymentManager contract
        require(
            shareholderSize <= IPaymentManager(paymentManager).getMaximumShareholdersLimit(),
            "reached maximum shareholder count"
        );

        uint8 j;
        for (uint8 i; i < shareholderSize; i++) {
            if (_shareholders[i].account != address(0) && _shareholders[i].value > 0) {
                shareholders[_lpAddress][_tokenId][j] = _shareholders[i];
                j += 1;
            }
        }
        listedNFTs[_lpAddress][_tokenId].shareholderSize = j;
    }

    /**
    * @notice resets the information of a previously listed NFT on a specific liquidity pool.
    * @param _lpAddress liquidity pool address
    * @param _tokenId NFT's tokenId
    */
    function _resetListedNFT(address _lpAddress, uint256 _tokenId, uint8 _shareholderSize) internal {
        for (uint8 i; i < _shareholderSize; i++) {
            delete shareholders[_lpAddress][_tokenId][i];
        }
        delete listedNFTs[_lpAddress][_tokenId];
    }

    /**
    * @notice Transfers a specified amount of ART tokens from the contract to a user.
    * @dev If the specified amount is greater than the contract's ART balance,
    * the remaining balance will be stored as failedBalance for the user, to be sent in future transactions.
    * @param _lpAddress The address of the liquidity pool.
    * @param _receiver The address of the recipient of the ART tokens.
    * @param _amount The amount of ART tokens to be transferred.
    */
    function _safeTransfer(address _lpAddress, address _receiver, uint256 _amount) internal {
        uint256 _totalBalance = art.balanceOf(address(this));
        _amount += users[_lpAddress][_receiver].failedBalance;
        if (_amount > _totalBalance) {
            users[_lpAddress][_receiver].failedBalance = _amount - _totalBalance;
            if (_totalBalance > 0) {
                art.safeTransfer(_receiver, _totalBalance);
            }
        } else {
            users[_lpAddress][_receiver].failedBalance = 0;
            art.safeTransfer(_receiver, _amount);
        }
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

import "./LibRoyalty.sol";
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IRoyalty {
    event RoyaltiesSet(uint256 indexed tokenId, LibRoyalty.Royalty[] royalties, LibRoyalty.Royalty[] previousRoyalties);

    event DefaultRoyaltiesSet(LibRoyalty.Royalty[] royalties, LibRoyalty.Royalty[] previousRoyalties);

    function getDefaultRoyalties() external view returns (LibRoyalty.Royalty[] memory);

    function getTokenRoyalties(uint256 _tokenId) external view returns (LibRoyalty.Royalty[] memory);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);

    function multiRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (LibRoyalty.Part[] memory);

    function setDefaultRoyaltyReceiver(address _defaultRoyaltyReceiver) external;

    function setDefaultRoyalties(LibRoyalty.Royalty[] memory _defaultRoyalties) external;

    function saveRoyalties(uint256 _tokenId, LibRoyalty.Royalty[] memory _royalties) external;
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