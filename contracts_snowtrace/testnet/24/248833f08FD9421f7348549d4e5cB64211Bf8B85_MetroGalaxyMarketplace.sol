// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/AcceptedToken.sol";
import "./interface/IMetroGalaxyMarketplace.sol";
import "./utils/AcceptedAssets.sol";

contract MetroGalaxyMarketplace is IMetroGalaxyMarketplace, AcceptedToken, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant MAX_MARKET_FEE = 1000;
    uint256 private constant BPS = 10000;
    uint256 public marketFeeInBps = 250;

    mapping(address => bool) public acceptedAssets;

    // mapping from assetId to listed assets
    mapping(bytes32 => mapping(address => Asset)) public listedAssets;
    mapping(bytes32 => mapping(address => Asset)) public offeredAssets;

    constructor(IERC20 _acceptedToken) AcceptedToken(_acceptedToken) {}

    /**
     * @dev List Metronion/accessories/assets for sale
     * If user want to update price or amount, user need to delist asset first
     * Can only call by assets owner
     * If asset doesn't support batch amount transfer, amount param should be 1
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param priceInWei Price in wei
     * @param amount Asset amount
     */
    function list(
        address assetAddr,
        uint256 assetId,
        uint256 priceInWei,
        uint256 amount
    ) external override nonReentrant {
        require(!paused(), "MetroGalaxyMarketplace: contract is paused");
        address seller = msg.sender;
        _requireAcceptedAssets(assetAddr);
        _requireAssetOwner(assetAddr, assetId, seller);
        _requireAssetAllowance(assetAddr, seller);
        _requireValidAssetAmount(assetAddr, amount);

        require(priceInWei > 0, "MetroGalaxyMarketplace: invalid price");

        bytes32 id = _getAssetId(assetAddr, assetId);

        Asset storage asset = listedAssets[id][seller];
        require(asset.amount == 0, "MetroGalaxyMarketplace: asset is already listed");
        asset.priceInWei = priceInWei;
        asset.amount = amount;

        // transfer asset to contract
        AcceptedAssets(assetAddr).safeTransferFrom(seller, address(this), assetId, amount);

        emit AssetListed(assetAddr, assetId, priceInWei, amount);
    }

    /**
     * @dev Delist Metronion/accessories/assets not for sale
     * Can only call by assets owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     */
    function delist(address assetAddr, uint256 assetId) external override nonReentrant {
        require(!paused(), "MetroGalaxyMarketplace: contract is paused");
        address seller = msg.sender;
        _requireAcceptedAssets(assetAddr);

        bytes32 id = _getAssetId(assetAddr, assetId);
        Asset memory asset = listedAssets[id][seller];
        require(asset.amount > 0, "MetroGalaxyMarketplace: asset is not listed");
        delete listedAssets[id][seller];

        // transfer asset to contract
        AcceptedAssets(assetAddr).safeTransferFrom(address(this), seller, assetId, asset.amount);

        emit AssetDelisted(assetAddr, assetId);
    }

    /**
     * @dev Place offer for assets
     * If user want to update price or amount, user need to cancel current offer first
     * Can only call by accounts that is not the owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param priceInWei Price in wei
     * @param amount Asset amount
     */
    function offer(
        address assetAddr,
        uint256 assetId,
        uint256 priceInWei,
        uint256 amount
    ) external payable override nonReentrant {
        require(!paused(), "MetroGalaxyMarketplace: contract is paused");
        address buyer = msg.sender;
        _requireAcceptedAssets(assetAddr);
        _requireValidAssetAmount(assetAddr, amount);
        require(priceInWei > 0, "MetroGalaxyMarketplace: invalid price");

        bytes32 id = _getAssetId(assetAddr, assetId);
        Asset storage asset = offeredAssets[id][buyer];
        uint256 totalPrice = priceInWei.mul(amount);

        require(acceptedToken.balanceOf(buyer) >= totalPrice, "MetroGalaxyMarketplace: insufficient token balance");
        _requireTokenAllowance(buyer, totalPrice);
        require(asset.amount == 0, "MetroGalaxyMarketplace: asset is already offered");

        asset.priceInWei = priceInWei;
        asset.amount = amount;
        acceptedToken.safeTransferFrom(buyer, address(this), totalPrice);

        emit AssetOffered(assetAddr, assetId, buyer, priceInWei, amount);
    }

    /**
     * @dev Cancel offer for assets
     * Can only call by accounts that is not the owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     */
    function cancelOffer(address assetAddr, uint256 assetId) external override nonReentrant {
        require(!paused(), "MetroGalaxyMarketplace: contract is paused");
        address buyer = msg.sender;
        _requireAcceptedAssets(assetAddr);
        bytes32 id = _getAssetId(assetAddr, assetId);
        Asset storage asset = offeredAssets[id][buyer];

        require(asset.amount > 0, "MetroGalaxyMarketplace: no asset offer found");
        delete offeredAssets[id][buyer];
        acceptedToken.safeTransfer(buyer, asset.priceInWei.mul(asset.amount));

        emit AssetOfferCancelled(assetAddr, assetId, buyer);
    }

    /**
     * @dev Take offer to sell asset
     * If asset is already listed, owner have to delist first
     * Can only call by assets owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param priceInWei Price in wei
     * @param amount Asset amount
     * @param buyer Buyer address
     */
    function takeOffer(
        address assetAddr,
        uint256 assetId,
        uint256 priceInWei,
        uint256 amount,
        address buyer
    ) external override nonReentrant {
        require(!paused(), "MetroGalaxyMarketplace: contract is paused");
        address seller = msg.sender;
        require(buyer != seller, "MetroGalaxyMarketplace: cannot take your own offer");

        _requireAcceptedAssets(assetAddr);
        _requireAssetOwner(assetAddr, assetId, seller);
        _requireAssetAllowance(assetAddr, seller);
        _requireValidAssetAmount(assetAddr, amount);

        bytes32 id = _getAssetId(assetAddr, assetId);
        Asset storage asset = offeredAssets[id][buyer];

        require(asset.amount > 0 && amount <= asset.amount, "MetroGalaxyMarketplace: invalid amount");
        require(asset.priceInWei == priceInWei, "MetroGalaxyMarketplace: invalid price");

        uint256 totalPrice = priceInWei.mul(amount);
        uint256 marketFee = _getMarketFee(totalPrice);

        asset.amount = asset.amount.sub(amount);

        // transfer accepted token to seller
        acceptedToken.safeTransfer(seller, totalPrice.sub(marketFee));
        acceptedToken.safeTransfer(owner(), marketFee);

        // transfer asset to buyer
        AcceptedAssets(assetAddr).safeTransferFrom(seller, buyer, assetId, amount);

        emit AssetOfferTaken(assetAddr, assetId, buyer, seller, priceInWei, amount);
    }

    /**
     * @dev Market buy assets
     * Assets have to be listed on marketplace
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param seller Address of seller
     * @param priceInWei Price want to buy
     * @param amount Asset amount
     */
    function buy(
        address assetAddr,
        uint256 assetId,
        address seller,
        uint256 priceInWei,
        uint256 amount
    ) external payable nonReentrant {
        require(!paused(), "MetroGalaxyMarketplace: contract is paused");

        address buyer = msg.sender;
        require(buyer != seller, "MetroGalaxyMarketplace: cannot buy your own assets");

        _requireAcceptedAssets(assetAddr);
        _requireValidAssetAmount(assetAddr, amount);

        bytes32 id = _getAssetId(assetAddr, assetId);
        Asset storage asset = listedAssets[id][seller];
        uint256 totalPrice = priceInWei.mul(amount);

        require(asset.amount > 0 && amount <= asset.amount, "MetroGalaxyMarketplace: invalid amount");
        require(priceInWei == asset.priceInWei, "MetroGalaxyMarketplace: invalid price");
        require(acceptedToken.balanceOf(buyer) >= totalPrice, "MetroGalaxyMarketplace: insufficient token balance");
        _requireTokenAllowance(buyer, totalPrice);

        uint256 marketFee = _getMarketFee(totalPrice);
        asset.amount = asset.amount.sub(amount);

        // transfer accepted token to seller
        acceptedToken.safeTransferFrom(buyer, seller, totalPrice.sub(marketFee));
        acceptedToken.safeTransferFrom(buyer, owner(), marketFee);

        // transfer asset to buyer
        AcceptedAssets(assetAddr).safeTransferFrom(address(this), buyer, assetId, amount);

        emit AssetBought(assetAddr, assetId, buyer, seller, priceInWei, amount);
    }

    /**
     * @dev Update accepted asset that can be trade on the marketplace
     * Can only called by the owner
     * @param assetAddr Asset address
     * @param isSupported Boolean
     */
    function updateAcceptedAsset(address assetAddr, bool isSupported) external override onlyOwner {
        acceptedAssets[assetAddr] = isSupported;
    }

    /**
     * @dev Update market fee without exceed MAX_MARKET_FEE
     * Can only called by the owner
     * @param feeBps fee in bps
     */
    function updateMarketFeeBps(uint256 feeBps) public onlyOwner {
        require(feeBps <= MAX_MARKET_FEE, "MetroGalaxyMarketplace: exceed max market fee");
        marketFeeInBps = feeBps;
    }

    /**
     * @dev Check if asset is supported
     */
    function isAcceptedAsset(address assetAddr) public view override returns (bool) {
        return acceptedAssets[assetAddr];
    }

    /**
     * @dev Get listed asset
     */
    function getListedAsset(
        address assetAddr,
        uint256 assetId,
        address account
    ) external view returns (Asset memory) {
        bytes32 id = _getAssetId(assetAddr, assetId);
        return listedAssets[id][account];
    }

    /**
     * @dev Get offered asset
     */
    function getOfferedAsset(
        address assetAddr,
        uint256 assetId,
        address account
    ) external view returns (Asset memory) {
        bytes32 id = _getAssetId(assetAddr, assetId);
        return offeredAssets[id][account];
    }

    /**
     * @dev Call by only owner to pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Call by only owner to unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function _requireAcceptedAssets(address assetAddr) private view {
        require(acceptedAssets[assetAddr], "MetroGalaxyMarketplace: asset is not supported");
    }

    function _requireAssetOwner(
        address assetAddr,
        uint256 assetId,
        address account
    ) private view {
        require(
            AcceptedAssets(assetAddr).balanceOf(account, assetId) > 0,
            "MetroGalaxyMarketplace: seller asset balance is not enough"
        );
    }

    function _requireAssetAllowance(address assetAddr, address account) private view {
        require(
            AcceptedAssets(assetAddr).isApprovedForAll(account, address(this)),
            "MetroGalaxyMarketplace: the marketplace is not authorized"
        );
    }

    function _requireTokenAllowance(address account, uint256 amount) private view {
        require(
            acceptedToken.allowance(account, address(this)) >= amount,
            "MetroGalaxyMarketplace: token allowance is not enough"
        );
    }

    function _requireValidAssetAmount(address assetAddr, uint256 amount) private pure {
        if (AcceptedAssets(assetAddr).isBatchAmountSupported()) {
            require(amount > 0, "MetroGalaxyMarketplace: invalid amount");
        } else {
            require(amount == 1, "MetroGalaxyMarketplace: invalid amount");
        }
    }

    function _getMarketFee(uint256 price) private view returns (uint256) {
        return price.mul(marketFeeInBps).div(BPS);
    }

    function _getAssetId(address assetAddr, uint256 assetId) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(assetAddr, assetId));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetroGalaxyMarketplace {
    struct Asset {
        uint256 priceInWei;
        uint256 amount;
    }

    event AssetListed(address indexed assetAddr, uint256 indexed assetId, uint256 priceInWei, uint256 amount);
    event AssetDelisted(address indexed assetAddr, uint256 indexed assetId);
    event AssetBought(
        address indexed assetAddr,
        uint256 indexed assetId,
        address buyer,
        address seller,
        uint256 priceInWei,
        uint256 amount
    );
    event AssetOffered(
        address indexed assetAddr,
        uint256 indexed assetId,
        address buyer,
        uint256 priceInWei,
        uint256 amount
    );
    event AssetOfferCancelled(address indexed assetAddr, uint256 indexed assetId, address buyer);
    event AssetOfferTaken(
        address indexed assetAddr,
        uint256 indexed assetId,
        address buyer,
        address seller,
        uint256 priceInWei,
        uint256 amount
    );

    /**
     * @dev List Metronion/accessories/assets for sale
     * If user want to update price or amount, user need to delist asset first
     * Can only call by assets owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param priceInWei Price in wei
     * @param amount Asset amount
     */
    function list(
        address assetAddr,
        uint256 assetId,
        uint256 priceInWei,
        uint256 amount
    ) external;

    /**
     * @dev Delist Metronion/accessories/assets not for sale
     * Can only call by assets owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     */
    function delist(address assetAddr, uint256 assetId) external;

    /**
     * @dev Place offer for assets
     * Can only call by accounts that is not the owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param priceInWei Price in wei
     * @param amount Asset amount
     */
    function offer(
        address assetAddr,
        uint256 assetId,
        uint256 priceInWei,
        uint256 amount
    ) external payable;

    /**
     * @dev Cancel offer for assets
     * Can only call by accounts that is not the owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     */
    function cancelOffer(address assetAddr, uint256 assetId) external;

    /**
     * @dev Take offer to sell asset
     * Can only call by assets owner
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param priceInWei Min price in wei
     * @param amount Asset amount
     * @param buyer Buyer address
     */
    function takeOffer(
        address assetAddr,
        uint256 assetId,
        uint256 priceInWei,
        uint256 amount,
        address buyer
    ) external;

    /**
     * @dev Market buy asset
     * @param assetAddr Asset address, should be in list supported address
     * @param assetId Asset id
     * @param seller Address of seller
     * @param priceInWei Price want to buy
     * @param amount Asset amount
     */
    function buy(
        address assetAddr,
        uint256 assetId,
        address seller,
        uint256 priceInWei,
        uint256 amount
    ) external payable;

    /**
     * @dev Update supported asset that can be trade on the marketplace
     * Asset should be ERC721 or ERC1155 type
     * Can only called by the owner
     * @param assetAddr Asset address
     * @param isSupported Boolean
     */
    function updateAcceptedAsset(address assetAddr, bool isSupported) external;

    /**
     * @dev Check if asset is supported
     */
    function isAcceptedAsset(address assetAddr) external view returns (bool);

    /**
     * @dev Get listed asset
     */
    function getListedAsset(
        address assetAddr,
        uint256 assetId,
        address account
    ) external view returns (Asset memory);

    /**
     * @dev Get offered asset
     */
    function getOfferedAsset(
        address assetAddr,
        uint256 assetId,
        address account
    ) external view returns (Asset memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract AcceptedAssets {
    /**
     * @dev Return asset balance of account
     * @param account Acccount address
     * @param assetId Asset ID
     */
    function balanceOf(address account, uint256 assetId) public view virtual returns (uint256);

    /**
     * @dev Return whether operator is allow to transfer owner's tokens
     * @param owner Owner address
     * @param operator Operator address
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool);

    /**
     * @dev Transfer amount of asset from address to address
     * @param from Sender address
     * @param to Receipient address
     * @param assetId Asset ID
     * @param amount Amount of asset
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 assetId,
        uint256 amount
    ) public virtual;

    /**
     * @dev Return whether asset is ERC721 or ERC1155 type
     */
    function isBatchAmountSupported() public pure virtual returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { PermissionGroup } from "./PermissionGroup.sol";

contract AcceptedToken is PermissionGroup {
    using SafeERC20 for IERC20;
    using Address for address;

    // Token to be used in the ecosystem.
    IERC20 public acceptedToken;

    constructor(IERC20 tokenAddress) {
        require(address(tokenAddress).isContract(), "AcceptedToken: address must be a deployed contract");
        acceptedToken = tokenAddress;
    }

    modifier collectTokenAsFee(uint256 amount, address destAddr) {
        require(acceptedToken.balanceOf(msg.sender) >= amount, "AcceptedToken: insufficient token balance");
        _;
        acceptedToken.safeTransferFrom(msg.sender, destAddr, amount);
    }

    /**
     * @dev Sets accepted token using in the ecosystem.
     */
    function setAcceptedTokenContract(IERC20 tokenAddr) external onlyOwner {
        require(address(tokenAddr) != address(0), "AcceptedToken: invalid accepted token");
        acceptedToken = tokenAddr;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract PermissionGroup is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @dev Adds an address as operator.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    /**
     * @dev Removes an address as operator.
     */
    function removeOperator(address operator) external onlyOwner {
        delete operators[operator];
    }

    /**
     * @dev Check if operator
     */
    function isOperator(address account) external view returns (bool) {
        return operators[account];
    }
}