// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(
    address owner
  ) public view virtual override returns (uint256) {
    require(owner != address(0), 'ERC721: address zero is not a valid owner');
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(
    uint256 tokenId
  ) public view virtual override returns (address) {
    address owner = _ownerOf(tokenId);
    require(owner != address(0), 'ERC721: invalid token ID');
    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, 'ERC721: approval to current owner');

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      'ERC721: approve caller is not token owner or approved for all'
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(
    uint256 tokenId
  ) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: caller is not token owner or approved'
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, '');
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: caller is not token owner or approved'
    );
    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return _owners[tokenId];
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _ownerOf(tokenId) != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) internal view virtual returns (bool) {
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, '');
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _beforeTokenTransfer(address(0), to, tokenId, 1);

    // Check that tokenId was not minted by `_beforeTokenTransfer` hook
    require(!_exists(tokenId), 'ERC721: token already minted');

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      _balances[to] += 1;
    }

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId, 1);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId, 1);

    // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
    owner = ERC721.ownerOf(tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    unchecked {
      // Cannot overflow, as that would require more tokens to be burned/transferred
      // out than the owner initially received through minting and transferring in.
      _balances[owner] -= 1;
    }
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId, 1);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721.ownerOf(tokenId) == from,
      'ERC721: transfer from incorrect owner'
    );
    require(to != address(0), 'ERC721: transfer to the zero address');

    _beforeTokenTransfer(from, to, tokenId, 1);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
    require(
      ERC721.ownerOf(tokenId) == from,
      'ERC721: transfer from incorrect owner'
    );

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    unchecked {
      // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
      // `from`'s balance is the number of token held, which is at least one before the current
      // transfer.
      // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      _balances[from] -= 1;
      _balances[to] += 1;
    }
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, 'ERC721: approve to caller');
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), 'ERC721: invalid token ID');
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert('ERC721: transfer to non ERC721Receiver implementer');
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}

  /**
   * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
   *
   * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
   * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
   * that `ownerOf(tokenId)` is `a`.
   */
  // solhint-disable-next-line func-name-mixedcase
  function __unsafe_increaseBalance(address account, uint256 amount) internal {
    _balances[account] += amount;
  }

  function __unsafe_decreaseBalance(address account, uint256 amount) internal {
    _balances[account] -= amount;
  }

  function _setOwner(uint256 tokenId, address from, address to) internal {
    require(to != address(0), 'CustomERC721: Invalid address');
    require(_exists(tokenId), 'CustomERC721: Token ID does not exist');
    require(
      _isApprovedOrOwner(from, tokenId),
      'CustomERC721: caller is not token owner or approved'
    );
    _owners[tokenId] = to;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './WeirdFrensNFT.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

contract Marketplace is AccessControl, ReentrancyGuard, ERC721Holder {
  using SafeMath for uint256;

  using ECDSA for bytes32;
  WeirdFrensNFT public weirdFrensContract;
  bytes32 public DOMAIN_SEPARATOR;
  address payable public admin;
  address payable public admin2;

  struct Offer {
    uint256 tokenId;
    address seller;
    uint256 price;
    uint256 nonce;
    bool isActive;
  }

  Offer[] public offers;

  mapping(uint256 => Offer) public tokenOffer;
  mapping(address => mapping(uint256 => uint256)) public nonces;

  event OfferCreated(
    uint256 indexed tokenId,
    address indexed seller,
    uint256 price
  );
  event OfferCancelled(
    uint256 indexed tokenId,
    address indexed seller,
    uint256 price
  );
  event OfferAccepted(
    uint256 indexed tokenId,
    address indexed buyer,
    address indexed seller,
    uint256 price
  );

  event LogHash(bytes32 hash);

  event AdminWithdrawal(uint256 transfer1, uint256 transfer2);

  constructor(
    address _owner,
    address weirdFrensNFT,
    address payable adminAddress,
    address payable admin2Address
  ) {
    weirdFrensContract = WeirdFrensNFT(weirdFrensNFT);
    _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    admin = adminAddress;
    admin2 = admin2Address;

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        ),
        keccak256(bytes('WeirdFrens Marketplace')),
        keccak256(bytes('1')),
        block.chainid,
        address(this)
      )
    );
  }

  /**

  @dev Creates an offer for a specific token by the seller. The function verifies the nonce, signature, and contract authorization.
  @param _tokenId The ID of the token to create an offer for.
  @param _price The price for which the token is offered.
  @param _nonce A nonce value for replay protection.
  @param _signature The seller's signature for the offer.
  @param seller The address of the seller.
  */
  function createOffer(
    uint256 _tokenId,
    uint256 _price,
    uint256 _nonce,
    bytes calldata _signature,
    address seller
  ) public {
    require(_nonce > nonces[seller][_tokenId], 'Invalid nonce');

    require(
      verifySignature(_tokenId, _price, _nonce, _signature, seller),
      'Invalid signature'
    );

    require(
      weirdFrensContract.getApproved(_tokenId) == address(this) ||
        weirdFrensContract.isApprovedForAll(seller, address(this)),
      'The contract is not authorized to manage the asset'
    );

    require(
      weirdFrensContract.ownerOf(_tokenId) == seller,
      'You are not the owner of this token'
    );
    require(_price > 0, 'Price must be greater than zero');
    require(
      tokenOffer[_tokenId].isActive == false,
      'There is already an active offer for this token'
    );
    nonces[seller][_tokenId] = _nonce;

    tokenOffer[_tokenId] = Offer({
      tokenId: _tokenId,
      seller: seller,
      price: _price,
      nonce: _nonce,
      isActive: true
    });

    emit OfferCreated(_tokenId, seller, _price);
  }

  /**

  @dev Cancels an existing offer for a specific token. The sender must be the seller of the token.
  @param _tokenId The ID of the token whose offer should be canceled.
  */
  function cancelOffer(uint256 _tokenId) public {
    Offer storage offer = tokenOffer[_tokenId];

    require(offer.isActive == true, 'There is no active offer for this token');
    require(msg.sender == offer.seller, 'You are not the seller of this token');

    emit OfferCancelled(_tokenId, offer.seller, offer.price);
    delete tokenOffer[_tokenId];
  }

  /**

  @dev Accepts an existing offer for a specific token. The sender must send the exact amount of the offer price.
  @param _tokenId The ID of the token whose offer should be accepted.
  */
  function acceptOffer(uint256 _tokenId) public payable nonReentrant {
    Offer storage offer = tokenOffer[_tokenId];
    require(offer.isActive == true, 'There is no active offer for this token');
    require(offer.seller != address(0), 'Invalid Seller');
    require(offer.seller != msg.sender, 'Seller cannot be buyer');

    require(
      msg.value == offer.price,
      'The amount sent must be equal to the offer price'
    );

    address seller = offer.seller;

    emit OfferAccepted(_tokenId, msg.sender, seller, offer.price);

    (bool success, ) = seller.call{value: msg.value.mul(95).div(100)}('');
    require(success, 'Transfer failed');

    // Increment the nonce for the seller and token combination
    nonces[offer.seller][_tokenId] = nonces[offer.seller][_tokenId] + 1;

    weirdFrensContract.safeTransferFrom(seller, msg.sender, offer.tokenId);
    delete tokenOffer[_tokenId];
  }

  /**

  @dev Returns the offer struct for a specific token.
  @param tokenId The ID of the token to retrieve the offer struct for.
  @return tokenId The token ID.
  @return seller The address of the seller.
  @return price The price of the offer.
  @return nonce The nonce value for replay protection.
  @return isActive A boolean indicating if the offer is active.
  */
  function getOfferStruct(
    uint256 tokenId
  ) external view returns (uint256, address, uint256, uint256, bool) {
    require(tokenId >= 0, 'Invalid tokenId');

    Offer memory x = tokenOffer[tokenId];

    return (x.tokenId, x.seller, x.price, x.nonce, x.isActive);
  }

  /**

  @dev Verifies a seller's signature for a specific token's offer.
  @param tokenId The ID of the token to verify the signature for.
  @param price The price of the offer.
  @param nonce A nonce value for replay protection.
  @param signature The seller's signature for the offer.
  @param seller The address of the seller.
  @return isValid A boolean indicating if the signature is valid.
  */
  function verifySignature(
    uint256 tokenId,
    uint256 price,
    uint256 nonce,
    bytes memory signature,
    address seller
  ) internal view returns (bool) {
    require(signature.length == 65, 'Invalid signature length');

    uint8 v;
    bytes32 r;
    bytes32 s;

    assembly {
      // first 32 bytes, after the length prefix
      r := mload(add(signature, 32))
      // second 32 bytes
      s := mload(add(signature, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(signature, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    require(v == 27 || v == 28, 'Invalid signature recovery identifier');

    bytes32 messageHash = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            keccak256(
              'Offer(uint256 tokenId,address seller,uint256 price,uint256 nonce)'
            ),
            tokenId,
            seller,
            price,
            nonce
          )
        )
      )
    );
    return (seller == ecrecover(messageHash, v, r, s));
  }

  receive() external payable {}

  function adminWithdraw() external onlyTeam {
    uint256 initialAmount = address(this).balance;
    uint256 adminCut = (initialAmount * 70) / 100;
    uint256 admin2Cut = (initialAmount * 30) / 100;

    (bool success, ) = admin.call{value: adminCut}('');
    require(success, 'Failed to send admin cut');

    (bool success2, ) = admin2.call{value: admin2Cut}('');
    require(success2, 'Failed to send admin2 cut');

    emit AdminWithdrawal(adminCut, admin2Cut);
  }

  /* ========== MODIFIER FUNCTIONS ========== */

  modifier onlyTeam() {
    require(admin2 == msg.sender || admin == msg.sender);
    _;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './imports/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

error FrenisGlitched();
error InsufficientAvax();
error DailyCooldownHasntExpired();
error NoMoreFrensLeftToMint();
error UserReachedMintCap();
error NotTheOwner();

contract WeirdFrensNFT is ERC721, AccessControl {
  /* ========== STATE VARIABLES ========== */

  // Using Counters library for token id generation
  using Counters for Counters.Counter;
  // Private variable to keep track of token ids
  Counters.Counter private _tokenIds;

  // Maximum amount of tokens that can be minted
  uint256 private MAX_MINT_COUNT;

  // Mapping to store the experience points of each user
  mapping(address => uint256) public playerExperience;
  // Mapping to store the number of tokens sponsored by each user
  mapping(address => uint256) public sponsorCount;
  // Mapping to store the number of tokens minted by each user
  mapping(address => uint256) public frensMinted;
  // Mapping to store whether a user is whitelisted or not
  mapping(address => bool) public isWhiteListed;
  // Mapping to store the last used time of free roll for each token
  mapping(uint256 => uint256) public freeRollLastUsedTime;

  // Amount of time required before a user can roll for free again
  uint256 public minimumTimeBeforeNextFreeRoll;
  address payable public admin;
  address payable public admin2;

  address public marketplaceContractAddress;

  // Costs of different rolls
  uint256 public backgroundRollCost;
  uint256 public bodyRollCost;
  uint256 public noseRollCost;
  uint256 public mouthRollCost;
  uint256 public eyeRollCost;
  uint256 public chestRollCost;
  uint256 public hairRollCost;
  uint256 public accessoryRollCost;

  // Amount of dust to gift to users
  uint256 public dustAmountToGift;
  // Amount of dust to gift to users
  uint256 public glitchRollCost;
  // Variable to store the last entropy used
  uint256 public lastEntropy;

  // Struct to store data of each token
  struct Fren {
    bool isGlitched;
    uint32 background;
    uint32 chest;
    uint32 nose;
    uint32 eyes;
    uint32 hair;
    uint32 accessory;
    uint32 mouth;
  }

  // Array to store all tokens
  Fren[] public frens;

  /* ========== EVENTS ========== */

  // Event to indicate a new token is minted
  event Mint(address indexed user, uint256 tokenId);

  // Event to indicate a token is sponsored
  event SponsoredMint(
    address indexed receiver,
    address indexed sponsor,
    uint256 tokenId
  );

  // Event to indicate a paid attribute roll has occurred
  event PaidAttributeRoll(
    uint256 indexed roll,
    string indexed AttributeType,
    address indexed user,
    uint256 tokenId
  );

  // Event to indicate a free attribute roll has occurred
  event FreeAttributeRoll(
    uint256 indexed roll,
    string indexed AttributeType,
    address indexed user,
    uint256 tokenId
  );

  // Event to indicate a glitch roll has occurred
  event GlitchRoll(
    bool indexed isGlitched,
    uint256 background,
    uint256 chest,
    uint256 nose,
    uint256 eyes,
    uint256 hair,
    uint256 accessory,
    uint256 mouth,
    uint256 indexed tokenId
  );

  event AdminWithdrawal(uint256 transfer1, uint256 transfer2);

  // This event is emitted when the whiteListUsers() function is called, and it includes the address of the user that has been whitelisted.
  event userWhitelisted(address indexed user);

  /* ========== CONSTRUCTOR ========== */
  constructor(
    address payable adminAddress,
    address payable admin2Address
  ) ERC721('WeirdFrens', 'FREN') {
    _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

    admin = adminAddress;
    admin2 = admin2Address;

    backgroundRollCost = 100000000000000000; // 0.1 AVAX
    noseRollCost = 100000000000000000; // 0.1 AVAX
    mouthRollCost = 100000000000000000; // 0.1 AVAX
    eyeRollCost = 100000000000000000; // 0.1 AVAX
    chestRollCost = 300000000000000000; // 0.3 AVAX
    hairRollCost = 300000000000000000; // 0.3 AVAX
    accessoryRollCost = 500000000000000000; // 0.5 AVAX
    dustAmountToGift = 9000000000000000; // 0.009 AVAX
    glitchRollCost = 1400000000000000000; // 1.4 AVAX

    MAX_MINT_COUNT = 10000;
    minimumTimeBeforeNextFreeRoll = 1 days;
    lastEntropy = block.timestamp;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  /**
   *@dev mints an item to the specified address.
   * @return uint256 the tokenId of the minted item
   */
  function mintItem() public returns (uint256) {
    address to = msg.sender;
    uint256 id = _tokenIds.current();

    if (id >= MAX_MINT_COUNT) revert NoMoreFrensLeftToMint();

    if (isWhiteListed[to]) {
      if (frensMinted[to] >= 40) revert UserReachedMintCap();
    } else {
      if (frensMinted[to] >= 20) revert UserReachedMintCap();
    }

    _mint(to, id);

    if (getApproved(id) == address(0)) {
      approve(marketplaceContractAddress, id);
    }

    frensMinted[to] += 1;
    _tokenIds.increment();
    freeRollLastUsedTime[id] = block.timestamp - 1 days;
    emit Mint(to, id);
    // lastEntropy = block.timestamp;

    frens.push(
      Fren({
        isGlitched: false,
        background: 2,
        chest: 0,
        nose: 4,
        eyes: 0,
        hair: 0,
        accessory: 0,
        mouth: 0
      })
    );

    return id;
  }

  /**
   * @dev Mints a batch of new items for the caller.
   * @param times The number of items to mint in the batch.
   * @return ids An array containing the IDs of the newly minted items.
   */
  function batchMint(uint256 times) public returns (uint256[] memory) {
    uint256[] memory ids = new uint256[](times);

    for (uint256 i = 0; i < times; i++) {
      ids[i] = mintItem();
    }

    return ids;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  }

  /**
   * @dev function that allows a user to send a small amount of "dust" to another address
   * and also creates a new "fren" token and assigns it to the recipient address.
   * It also increments various counts and updates some other storage variables.
   * @param to address to which dust should be sent
   * @return the tokenId of the created fren
   */
  function sponsoredMint(address to) public payable returns (uint256) {
    if (msg.value < dustAmountToGift) revert InsufficientAvax();

    // send them some dust
    (bool sent, bytes memory data) = to.call{value: dustAmountToGift}('');
    require(sent, 'Failed to send AVAX');

    uint256 id = _tokenIds.current();
    if (id >= MAX_MINT_COUNT) revert NoMoreFrensLeftToMint();

    if (isWhiteListed[to]) {
      if (frensMinted[to] >= 40) revert UserReachedMintCap();
    } else {
      if (frensMinted[to] >= 20) revert UserReachedMintCap();
    }

    _mint(to, id);
    frensMinted[to] += 1;
    _tokenIds.increment();

    if (getApproved(id) == address(0)) {
      approve(marketplaceContractAddress, id);
    }

    unchecked {
      sponsorCount[msg.sender] += 1;
      playerExperience[msg.sender] += 1;
    }
    freeRollLastUsedTime[id] = block.timestamp - 1 days;

    emit SponsoredMint(to, msg.sender, id);
    // lastEntropy = block.timestamp;

    frens.push(
      Fren({
        isGlitched: false,
        background: 2,
        chest: 0,
        nose: 4,
        eyes: 0,
        hair: 0,
        accessory: 0,
        mouth: 0
      })
    );

    return id;
  }

  /**
   * @dev Override of a built-in ERC721 function that runs some logic before a token transfer occurs
   * @param from the current owner of the token
   * @param to the address to which the token will be transferred
   * @param tokenId the tokenId of the token to be transferred
   * @param batchSize the number of tokens to be transferred
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721) {
    require(
      _isApprovedOrOwner(marketplaceContractAddress, tokenId),
      'ERC721: caller is not token owner or approved'
    );

    if (getApproved(tokenId) == address(0)) {
      approve(marketplaceContractAddress, tokenId);
    }

    _transfer(from, to, tokenId);

    approve(marketplaceContractAddress, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721) {
    require(
      _isApprovedOrOwner(marketplaceContractAddress, tokenId),
      'ERC721: caller is not token owner or approved'
    );

    if (getApproved(tokenId) == address(0)) {
      approve(marketplaceContractAddress, tokenId);
    }

    _transfer(from, to, tokenId);

    approve(marketplaceContractAddress, tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    require(
      ERC721.ownerOf(tokenId) == from ||
        _isApprovedOrOwner(marketplaceContractAddress, tokenId),
      'WeirdFrens: transfer from incorrect owner'
    );

    require(to != address(0), 'ERC721: transfer to the zero address');

    _beforeTokenTransfer(from, to, tokenId, 1);

    ERC721.__unsafe_increaseBalance(to, 1);

    ERC721.__unsafe_decreaseBalance(from, 1);

    // Update the token ownership
    ERC721._setOwner(tokenId, from, to);

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  function approve(address to, uint256 tokenId) public override(ERC721) {
    require(
      msg.sender == ownerOf(tokenId) ||
        (msg.sender != ownerOf(tokenId) && to == marketplaceContractAddress),
      'WeirdFrensNFT: caller must be either the owner or approving to the marketplace contract'
    );

    _approve(to, tokenId);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  /**
   * @dev Performs a glitch roll on a specified token, updating its attributes and possibly glitching it.
   * @notice The caller must be the owner of the token and provide sufficient payment for the roll.
   * @param tokenId The ID of the token to perform the glitch roll on.
   */
  function glitchRoll(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < glitchRollCost) revert InsufficientAvax();

    playerExperience[msg.sender] += 6;

    uint256 playerLevel = getPlayerLevel(msg.sender);

    fren.background = uint32(
      weightedRoll(
        generateItems(9),
        generateUpdatedBackgroundWeights(playerLevel)
      )
    );

    fren.chest = uint32(
      weightedRoll(generateItems(25), generateUpdatedChestWeights(playerLevel))
    );

    fren.nose = uint32(
      weightedRoll(generateItems(9), generateUpdatedNoseWeights(playerLevel))
    );

    fren.eyes = uint32(
      weightedRoll(generateItems(20), generateUpdatedEyeWeights(playerLevel))
    );

    fren.hair = uint32(
      weightedRoll(generateItems(34), generateUpdatedHairWeights(playerLevel))
    );

    fren.accessory = uint32(
      weightedRoll(
        generateItems(15),
        generateUpdatedAccessoryWeights(playerLevel)
      )
    );

    fren.mouth = uint32(
      weightedRoll(generateItems(14), generateUpdatedMouthWeights(playerLevel))
    );

    fren.isGlitched = didGlitch();

    emit GlitchRoll(
      fren.isGlitched,
      fren.background,
      fren.chest,
      fren.nose,
      fren.eyes,
      fren.hair,
      fren.accessory,
      fren.mouth,
      tokenId
    );
  }

  /**
   * @dev Allows a user to roll for a new background for their Fren token
   * @param tokenId the tokenId of the Fren for which to roll a new background
   * @notice The user must have enough AVAX to pay for the roll and the Fren token must not be glitched.
   */
  function rollNewBackground(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < backgroundRollCost) revert InsufficientAvax();
    unchecked {
      playerExperience[msg.sender] += 1;
    }

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(
        generateItems(9),
        generateUpdatedBackgroundWeights(playerLevel)
      )
    );
    fren.background = roll;

    emit PaidAttributeRoll(roll, 'BackgroundRoll', msg.sender, tokenId);
  }

  /**
  * @dev Allows a user to roll for a new background for their Fren token for free,
  subject to a daily cooldown period
  * @param tokenId the tokenId of the Fren for which to roll a new background
  * @notice The Fren token must not be glitched.
  */

  function freeRollNewBackground(uint256 tokenId) public {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (!minimumRequiredTimeHasPassed(freeRollLastUsedTime[tokenId]))
      revert DailyCooldownHasntExpired();

    freeRollLastUsedTime[tokenId] = block.timestamp;

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(
        generateItems(9),
        generateUpdatedBackgroundWeights(playerLevel)
      )
    );
    fren.background = roll;

    emit FreeAttributeRoll(roll, 'BackgroundRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new chest for their Fren token
  @param tokenId the tokenId of the Fren for which to roll a new chest
  @notice The user must have enough AVAX to pay for the roll and the Fren token must not be glitched.
  */

  function rollNewChest(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < chestRollCost) revert InsufficientAvax();
    unchecked {
      playerExperience[msg.sender] += 1;
    }
    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(25), generateUpdatedChestWeights(playerLevel))
    );
    fren.chest = roll;

    emit PaidAttributeRoll(roll, 'ChestRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new chest for their Fren token for free,
  subject to a daily cooldown period
  @param tokenId the tokenId of the Fren for which to roll a new chest
  @notice The Fren token must not be glitched.
  */
  function freeRollNewChest(uint256 tokenId) public {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (!minimumRequiredTimeHasPassed(freeRollLastUsedTime[tokenId]))
      revert DailyCooldownHasntExpired();

    freeRollLastUsedTime[tokenId] = block.timestamp;
    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(25), generateUpdatedChestWeights(playerLevel))
    );
    fren.chest = roll;

    emit FreeAttributeRoll(roll, 'ChestRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new nose for their Fren token
  @param tokenId the tokenId of the Fren for which to roll a new nose
  @notice The user must have enough AVAX to pay for the roll and the Fren token must not be glitched.
  */

  function rollNewNose(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < noseRollCost) revert InsufficientAvax();
    unchecked {
      playerExperience[msg.sender] += 1;
    }

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(9), generateUpdatedNoseWeights(playerLevel))
    );

    fren.nose = roll;

    emit PaidAttributeRoll(roll, 'NoseRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new nose for their Fren token for free,
  subject to a daily cooldown period
  @param tokenId the tokenId of the Fren for which to roll a new nose
  @notice The Fren token must not be glitched.
  */

  function freeRollNewNose(uint256 tokenId) public {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (!minimumRequiredTimeHasPassed(freeRollLastUsedTime[tokenId]))
      revert DailyCooldownHasntExpired();

    freeRollLastUsedTime[tokenId] = block.timestamp;

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(9), generateUpdatedNoseWeights(playerLevel))
    );

    fren.nose = roll;

    emit FreeAttributeRoll(roll, 'NoseRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new mouth for their Fren token
  @param tokenId the tokenId of the Fren for which to roll a new mouth
  @notice The user must have enough AVAX to pay for the roll and the Fren token must not be glitched.
  */
  function rollNewMouth(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < mouthRollCost) revert InsufficientAvax();
    unchecked {
      playerExperience[msg.sender] += 1;
    }

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(14), generateUpdatedMouthWeights(playerLevel))
    );

    fren.mouth = roll;

    emit PaidAttributeRoll(roll, 'MouthRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new mouth for their Fren token for free,
  subject to a daily cooldown period
  @param tokenId the tokenId of the Fren for which to roll a new mouth
  @notice The Fren token must not be glitched.
  */
  function freeRollNewMouth(uint256 tokenId) public {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (!minimumRequiredTimeHasPassed(freeRollLastUsedTime[tokenId]))
      revert DailyCooldownHasntExpired();

    freeRollLastUsedTime[tokenId] = block.timestamp;

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(14), generateUpdatedMouthWeights(playerLevel))
    );

    fren.mouth = roll;

    emit FreeAttributeRoll(roll, 'MouthRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new eye for their Fren token
  @param tokenId the tokenId of the Fren for which to roll a new eye
  @notice The user must have enough AVAX to pay for the roll and the Fren token must not be glitched.
  */
  function rollNewEye(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < eyeRollCost) revert InsufficientAvax();
    unchecked {
      playerExperience[msg.sender] += 1;
    }

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(20), generateUpdatedEyeWeights(playerLevel))
    );

    fren.eyes = roll;

    emit PaidAttributeRoll(roll, 'EyeRoll', msg.sender, tokenId);
  }

  /**

  @dev Allows a user to roll for a new eye for their Fren token for free,
  subject to a daily cooldown period
  @param tokenId the tokenId of the Fren for which to roll a new eye
  @notice The Fren token must not be glitched.
  */
  function freeRollNewEye(uint256 tokenId) public {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (!minimumRequiredTimeHasPassed(freeRollLastUsedTime[tokenId]))
      revert DailyCooldownHasntExpired();

    freeRollLastUsedTime[tokenId] = block.timestamp;

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(20), generateUpdatedEyeWeights(playerLevel))
    );

    fren.eyes = roll;

    emit FreeAttributeRoll(roll, 'EyeRoll', msg.sender, tokenId);
  }

  /**
   * @dev Allows a user to roll for a new hair for their Fren token
   * @param tokenId the tokenId of the Fren for which to roll a new hair
   * @notice The user must have enough AVAX to pay for the roll and the Fren token must not be glitched.
   */
  function rollNewHair(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < hairRollCost) revert InsufficientAvax();
    unchecked {
      playerExperience[msg.sender] += 1;
    }

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(34), generateUpdatedHairWeights(playerLevel))
    );

    fren.hair = roll;
    emit PaidAttributeRoll(roll, 'HairRoll', msg.sender, tokenId);
  }

  /**
   * @dev Allows a user to roll for a new hair for their Fren token for free,
   * subject to a daily cooldown period
   * @param tokenId the tokenId of the Fren for which to roll a new hair
   * @notice The Fren token must not be glitched.
   */
  function freeRollNewHair(uint256 tokenId) public {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (!minimumRequiredTimeHasPassed(freeRollLastUsedTime[tokenId]))
      revert DailyCooldownHasntExpired();

    freeRollLastUsedTime[tokenId] = block.timestamp;

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(generateItems(34), generateUpdatedHairWeights(playerLevel))
    );

    fren.hair = roll;
    emit FreeAttributeRoll(roll, 'HairRoll', msg.sender, tokenId);
  }

  /**
   * @dev Allows a user to roll for a new accessory for their Fren token
   * @param tokenId the tokenId of the Fren for which to roll a new accessory
   * @notice The user must have enough AVAX to pay for the roll and the Fren token must not be glitched.
   */
  function rollNewAccessory(uint256 tokenId) public payable {
    if (super.ownerOf(tokenId) != msg.sender) revert NotTheOwner();

    Fren storage fren = frens[tokenId];

    if (fren.isGlitched) revert FrenisGlitched();

    if (msg.value < accessoryRollCost) revert InsufficientAvax();
    unchecked {
      playerExperience[msg.sender] += 1;
    }

    uint256 playerLevel = getPlayerLevel(msg.sender);

    uint32 roll = uint32(
      weightedRoll(
        generateItems(15),
        generateUpdatedAccessoryWeights(playerLevel)
      )
    );

    fren.accessory = roll;

    emit PaidAttributeRoll(roll, 'AccessoryRoll', msg.sender, tokenId);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function adminWithdraw() external onlyTeam {
    uint256 initialAmount = address(this).balance;
    uint256 adminCut = (initialAmount * 95) / 100;

    uint256 admin2Cut = (initialAmount * 5) / 100;

    (bool success, ) = admin.call{value: adminCut}('');
    require(success, 'Failed to send admin cut');

    (bool success2, ) = admin2.call{value: admin2Cut}('');
    require(success2, 'Failed to send admin2 cut');

    emit AdminWithdrawal(adminCut, admin2Cut);
  }

  function whiteListUsers(
    address[] calldata users
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < users.length; i++) {
      isWhiteListed[users[i]] = true;
      emit userWhitelisted(users[i]);
    }
  }

  function setMarketplaceContractAddress(
    address contractAddress
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    marketplaceContractAddress = contractAddress;
  }

  /* ========== MODIFIER FUNCTIONS ========== */

  modifier onlyTeam() {
    require(admin2 == msg.sender || admin == msg.sender);
    _;
  }

  /* ========== VIEWS ========== */

  /**
   * @dev Generates an array of background weights used for the rollNewBackground function
   * @return uint256[] memory - An array of weights for the different backgrounds
   */
  function generateBackgroundWeights()
    internal
    pure
    returns (uint256[] memory)
  {
    uint256[] memory weights = new uint256[](9);

    weights[0] = 19500;
    weights[1] = 19500;
    weights[2] = 19500;
    weights[3] = 19500;
    weights[4] = 4400;
    weights[5] = 4400;
    weights[6] = 4400;
    weights[7] = 4400;
    weights[8] = 4400;

    return weights;
  }

  /**
   * @dev Generates updated background weights based on the player's level.
   * @param playerLevel The level of the player for whom the background weights are being generated.
   * @return updatedBackgroundWeights An array of updated background weights considering the player's level.
   */
  function generateUpdatedBackgroundWeights(
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256[] memory backgroundWeights = generateBackgroundWeights();
    uint256[] memory updatedBackgroundWeights = applyLevelBasedBonus(
      backgroundWeights,
      playerLevel
    );
    return updatedBackgroundWeights;
  }

  /**
   * @dev Generates an array of chest weights used for the rollNewChest function
   * @return uint256[] memory - An array of weights for the different chests
   */
  function generateChestWeights() internal pure returns (uint256[] memory) {
    uint256[] memory weights = new uint256[](25);

    weights[0] = 6900;
    weights[1] = 6900;
    weights[2] = 6900;
    weights[3] = 6900;
    weights[4] = 6900;
    weights[5] = 5800;
    weights[6] = 4800;
    weights[7] = 4800;
    weights[8] = 4800;
    weights[9] = 4800;
    weights[10] = 4800;
    weights[11] = 4800;
    weights[12] = 3800;
    weights[13] = 3800;
    weights[14] = 3800;
    weights[15] = 3800;
    weights[16] = 3800;
    weights[17] = 3800;
    weights[18] = 3800;
    weights[19] = 3800;
    weights[20] = 100;
    weights[21] = 100;
    weights[22] = 100;
    weights[23] = 100;
    weights[24] = 100;

    return weights;
  }

  /**
   * @dev Generates updated chest weights based on the player's level.
   * @param playerLevel The level of the player for whom the chest weights are being generated.
   * @return updatedChestWeights An array of updated chest weights considering the player's level.
   */
  function generateUpdatedChestWeights(
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256[] memory chestWeights = generateChestWeights();
    uint256[] memory updatedChestWeights = applyLevelBasedBonus(
      chestWeights,
      playerLevel
    );
    return updatedChestWeights;
  }

  /**
   * @dev Generates an array of nose weights used for the rollNewnose function
   * @return uint256[] memory - An array of weights for the different noses
   */
  function generateNoseWeights() internal pure returns (uint256[] memory) {
    uint256[] memory weights = new uint256[](9);

    weights[0] = 11112;
    weights[1] = 11111;
    weights[2] = 11111;
    weights[3] = 11111;
    weights[4] = 11111;
    weights[5] = 11111;
    weights[6] = 11111;
    weights[7] = 11111;
    weights[8] = 11111;

    return weights;
  }

  /**
   * @dev Generates updated nose weights based on the player's level.
   * @param playerLevel The level of the player for whom the nose weights are being generated.
   * @return updatedNoseWeights An array of updated nose weights considering the player's level.
   */
  function generateUpdatedNoseWeights(
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256[] memory noseWeights = generateNoseWeights();
    uint256[] memory updatedNoseWeights = applyLevelBasedBonus(
      noseWeights,
      playerLevel
    );
    return updatedNoseWeights;
  }

  /**
   * @dev Generates an array of eye weights used for the rollNeweye function
   * @return uint256[] memory - An array of weights for the different eyes
   */
  function generateEyeWeights() internal pure returns (uint256[] memory) {
    uint256[] memory weights = new uint256[](20);

    weights[0] = 7100;
    weights[1] = 7100;
    weights[2] = 7100;
    weights[3] = 7100;
    weights[4] = 7100;
    weights[5] = 7100;
    weights[6] = 5900;
    weights[7] = 5900;
    weights[8] = 5900;
    weights[9] = 4300;
    weights[10] = 4300;
    weights[11] = 4300;
    weights[12] = 4300;
    weights[13] = 4300;
    weights[14] = 3500;
    weights[15] = 3500;
    weights[16] = 3500;
    weights[17] = 3500;
    weights[18] = 2100;
    weights[19] = 2100;

    return weights;
  }

  /**
   * @dev Generates updated eye weights based on the player's level.
   * @param playerLevel The level of the player for whom the eye weights are being generated.
   * @return updatedEyeWeights An array of updated eye weights considering the player's level.
   */
  function generateUpdatedEyeWeights(
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256[] memory eyeWeights = generateEyeWeights();
    uint256[] memory updatedEyeWeights = applyLevelBasedBonus(
      eyeWeights,
      playerLevel
    );
    return updatedEyeWeights;
  }

  /**
   * @dev Generates an array of mouth weights used for the rollNewMouth function
   * @return uint256[] memory - An array of weights for the different mouths
   */
  function generateMouthWeights() internal pure returns (uint256[] memory) {
    uint256[] memory weights = new uint256[](14);

    weights[0] = 9300;
    weights[1] = 9300;
    weights[2] = 9300;
    weights[3] = 9300;
    weights[4] = 9300;
    weights[5] = 9300;
    weights[6] = 9200;
    weights[7] = 9200;
    weights[8] = 9200;
    weights[9] = 5900;
    weights[10] = 5900;
    weights[11] = 1600;
    weights[12] = 1600;
    weights[13] = 1600;

    return weights;
  }

  /**
   * @dev Generates updated mouth weights based on the player's level.
   * @param playerLevel The level of the player for whom the mouth weights are being generated.
   * @return updatedMouthWeights An array of updated mouth weights considering the player's level.
   */
  function generateUpdatedMouthWeights(
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256[] memory mouthWeights = generateMouthWeights();
    uint256[] memory updatedMouthWeights = applyLevelBasedBonus(
      mouthWeights,
      playerLevel
    );
    return updatedMouthWeights;
  }

  /**
   * @dev Generates an array of hair weights used for the rollNewHair function
   * @return uint256[] memory - An array of weights for the different hairs
   */
  function generateHairWeights() internal pure returns (uint256[] memory) {
    uint256[] memory weights = new uint256[](34);

    weights[0] = 6580;
    weights[1] = 6580;
    weights[2] = 6580;
    weights[3] = 6580;
    weights[4] = 6580;
    weights[5] = 6580;
    weights[6] = 6580;
    weights[7] = 5590;
    weights[8] = 3200;
    weights[9] = 3200;
    weights[10] = 3200;
    weights[11] = 3200;
    weights[12] = 3200;
    weights[13] = 3200;
    weights[14] = 3200;
    weights[15] = 2700;
    weights[16] = 2700;
    weights[17] = 2700;
    weights[18] = 2700;
    weights[19] = 2700;
    weights[20] = 2700;
    weights[21] = 2700;
    weights[22] = 2100;
    weights[23] = 2100;
    weights[24] = 2100;
    weights[25] = 100;
    weights[26] = 100;
    weights[27] = 100;
    weights[28] = 100;
    weights[29] = 100;
    weights[30] = 100;
    weights[31] = 50;
    weights[32] = 50;
    weights[33] = 50;

    return weights;
  }

  /**
   * @dev Generates updated hair weights based on the player's level.
   * @param playerLevel The level of the player for whom the hair weights are being generated.
   * @return updatedHairWeights An array of updated hair weights considering the player's level.
   */

  function generateUpdatedHairWeights(
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256[] memory hairWeights = generateHairWeights();
    uint256[] memory updatedHairWeights = applyLevelBasedBonus(
      hairWeights,
      playerLevel
    );
    return updatedHairWeights;
  }

  /**
   * @dev Generates an array of accessory weights used for the rollNewAccessory function
   * @return uint256[] memory - An array of weights for the different accessorys
   */
  function generateAccessoryWeights() internal pure returns (uint256[] memory) {
    uint256[] memory weights = new uint256[](15);

    weights[0] = 68915;
    weights[1] = 4548;
    weights[2] = 4548;
    weights[3] = 4548;
    weights[4] = 4548;
    weights[5] = 3203;
    weights[6] = 3100;
    weights[7] = 3100;
    weights[8] = 3100;
    weights[9] = 100;
    weights[10] = 100;
    weights[11] = 100;
    weights[12] = 30;
    weights[13] = 30;
    weights[14] = 30;

    return weights;
  }

  /**
   * @dev Generates updated accessory weights based on the player's level.
   * @param playerLevel The level of the player for whom the accessory weights are being generated.
   * @return updatedAccessoryWeights An array of updated accessory weights considering the player's level.
   */

  function generateUpdatedAccessoryWeights(
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256[] memory accessoryWeights = generateAccessoryWeights();
    uint256[] memory updatedAccessoryWeights = applyLevelBasedBonus(
      accessoryWeights,
      playerLevel
    );
    return updatedAccessoryWeights;
  }

  /**
   * @dev Applies a level-based bonus to the item weights, increasing the likelihood of obtaining rarer items.
   * @param weights The initial item weights, as an array of uint256 values.
   * @param playerLevel The player's level, used to calculate the bonus to apply.
   * @return updatedWeights The updated item weights after applying the level-based bonus.
   */
  function applyLevelBasedBonus(
    uint256[] memory weights,
    uint256 playerLevel
  ) internal pure returns (uint256[] memory) {
    uint256 rareItemsStartIndex = weights.length - 4;
    uint256 totalBoost = 0;
    uint256 maxBoostPercentage = 13;
    for (uint256 i = rareItemsStartIndex; i < weights.length; i++) {
      uint256 bonus = ((playerLevel * playerLevel * maxBoostPercentage) /
        (60 * 60)) * 100;
      uint256 newItemWeight = weights[i] + bonus;
      totalBoost += newItemWeight - weights[i];
      weights[i] = newItemWeight;
    }

    uint256 totalReduction = totalBoost / 4;
    for (uint256 i = 0; i < 4; i++) {
      weights[i] -= totalReduction;
    }

    return weights;
  }

  /**
   * @dev generateItems function generates an array of items of a given count
   * @param count uint256 - The number of items to generate
   * @return items uint256[] - An array of generated items
   */
  function generateItems(
    uint256 count
  ) internal pure returns (uint256[] memory) {
    uint256[] memory items = new uint256[](count);
    for (uint256 i = 0; i < count; i++) {
      items[i] = i;
    }
    return items;
  }

  /**
   * @dev random function generates a random number
   * @return num uint256 - A random number
   */
  function random() internal view returns (uint256) {
    uint256 num = uint256(
      keccak256(
        abi.encodePacked(
          lastEntropy,
          block.difficulty,
          block.timestamp,
          address(this).balance,
          tx.gasprice,
          msg.sender
        )
      )
    );

    if (
      num >
      99999999999999999999999999999999999999999999999999999999999999999999999999999
    ) {
      return num / 10 ** 73;
    }

    return num / 10 ** 72;
  }

  /**
   * Check if a glitch occurred. 10% chance of glitching.
   *
   * @dev The function returns true if the result of the keccak256 hash of the input parameters,
   * converted to a uint256 value, is less than the threshold of 0.03 * 10^18. The input parameters
   * are: lastEntropy, block.difficulty, block.timestamp, and address(this).balance.
   *
   * @return A boolean value indicating whether a glitch occurred.
   */
  function didGlitch() public view returns (bool) {
    uint256 hash = uint256(
      keccak256(
        abi.encodePacked(
          lastEntropy,
          block.difficulty,
          block.timestamp,
          address(this).balance
        )
      )
    );

    uint256 last5Digits = hash % 100000;
    return last5Digits < 10000;
  }

  /**
   * @dev weightedRoll function generates a random item index based on the given items and weights
   * @param items uint256[] - An array of items to choose from
   * @param weights uint256[] - An array of weights for each item
   * @return itemIndex uint256 - A randomly selected item index
   */
  function weightedRoll(
    uint256[] memory items,
    uint256[] memory weights
  ) internal returns (uint256 itemIndex) {
    uint256 sumOfWeights = 0;

    uint256 rand = random();

    lastEntropy = block.timestamp;

    for (uint256 i = 0; i < items.length; i++) {
      sumOfWeights += weights[i];

      if (sumOfWeights > rand) {
        return i;
      }
    }
  }

  /**
   * @dev getFrenStruct returns a struct with the given tokenId's Fren data
   * @param tokenId uint256 - The tokenId of the Fren to retrieve
   * @return (bool, uint32, uint32, uint32, uint32, uint32, uint32, uint32, bytes32, string memory) - A struct with the Fren's data
   */
  function getFrenStruct(
    uint256 tokenId
  )
    external
    view
    returns (bool, uint32, uint32, uint32, uint32, uint32, uint32, uint32)
  {
    Fren memory x = frens[tokenId];

    return (
      x.isGlitched,
      x.background,
      x.chest,
      x.nose,
      x.eyes,
      x.hair,
      x.accessory,
      x.mouth
    );
  }

  /**
   * @dev getPlayerLevel returns the player's level based on their experience
   * @param user address - The address of the player to retrieve the level for
   * @return level uint256 - The player's level
   */
  function getPlayerLevel(address user) public view returns (uint256) {
    return calculateLevel(playerExperience[user]);
  }

  /**
   * @dev getPlayerExperience returns the player's experience
   * @param user address - The address of the player to retrieve the experience for
   * @return experience uint256 - The player's experience
   */
  function getPlayerExperience(address user) external view returns (uint256) {
    return (playerExperience[user]);
  }

  /**
   * @dev getNumberOfMintsByUser returns the number of Frens minted by a user
   * @param user address - The address of the user to retrieve the number of mints for
   * @return numberOfMints uint256 - The number of Frens minted by the user
   */
  function getNumberOfMintsByUser(
    address user
  ) external view returns (uint256) {
    return (frensMinted[user]);
  }

  /**
   * @dev _baseURI returns the base URI for the contract
   * @return baseURI string - The base URI for the contract
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return 'https://weirdfrens.com/api/token/';
  }

  /**
   * @dev get the remaining time before user can roll for free again.
   * @param tokenId the tokenId of the Fren
   * @return time uint256 the remaining time in seconds
   */
  function getFreeRollRemainingCooldown(
    uint256 tokenId
  ) external view returns (uint256 time) {
    return freeRollLastUsedTime[tokenId];
  }

  /** @dev checks if the minimum amount of time before user can roll for free again.
   * @param timestamp The time to check against
   * @return bool
   */
  function minimumRequiredTimeHasPassed(
    uint256 timestamp
  ) private view returns (bool) {
    return (block.timestamp >= timestamp + minimumTimeBeforeNextFreeRoll);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   * @param interfaceId the interface ID to check
   * @return bool true if the contract supports the given interface, false otherwise
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl, ERC721) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev check if the user is whitelisted
   * @param user the user to check
   * @return bool true if the user is whitelisted, false otherwise
   */
  function isUserWhitelisted(address user) external view returns (bool) {
    return isWhiteListed[user];
  }

  /**
   * @dev calculate the level of a user based on their experience points
   * @param experiencePoints the user's experience points
   * @return level uint256 the user's level
   */
  function calculateLevel(
    uint256 experiencePoints
  ) internal pure returns (uint256 level) {
    // 5346  (level 99)
    // 2070   (level 60)

    if (experiencePoints > 2070) {
      return 60;
    }
    experiencePoints = ((experiencePoints + 10) * 8) + 1;
    experiencePoints = (sqrt(experiencePoints) + 1);
    level = ((experiencePoints * 50) / 100) - 5;
  }

  /**
   * @dev calculate the square root of a number
   * @param y the number to calculate the square root of
   * @return z uint256 the square root of the number
   */
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}