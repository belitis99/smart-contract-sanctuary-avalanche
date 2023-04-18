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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

pragma solidity ^0.8.10;

abstract contract AdminControl {
    address public admin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    function initAdminControl(address _admin) internal {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(admin, _admin);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./AdminControl.sol";
import "../interfaces/IAnycallProxy.sol";
import "../interfaces/IAnycallExecutor.sol";
import "../interfaces/IFeePool.sol";

abstract contract AnyCallApp is AdminControl {
    address public callProxy;

    // associated client app on each chain
    mapping(uint256 => address) public clientPeers; // key is chainId

    modifier onlyExecutor() {
        require(
            msg.sender == IAnycallProxy(callProxy).executor(),
            "AppBase: onlyExecutor"
        );
        _;
    }

    function initAnyCallApp(address _callProxy, address _admin) public {
        require(_callProxy != address(0));
        callProxy = _callProxy;
        initAdminControl(_admin);
    }

    receive() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdraw(address _to, uint256 _amount) external onlyAdmin {
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function setCallProxy(address _callProxy) external onlyAdmin {
        require(_callProxy != address(0));
        callProxy = _callProxy;
    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyAdmin {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }

    function depositFee() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdrawFee(address _to, uint256 _amount) external onlyAdmin {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function withdrawAllFee(address _pool, address _to) external onlyAdmin {
        uint256 _amount = IFeePool(_pool).executionBudget(address(this));
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function executionBudget() external view returns (uint256) {
        address _pool = IAnycallProxy(callProxy).config();
        return IFeePool(_pool).executionBudget(address(this));
    }

    /// @dev Customized logic for processing incoming messages
    function _anyExecute(
        uint256 fromChainID,
        bytes memory data
    ) internal virtual returns (bool success, bytes memory result);

    /// @dev Customized logic for processing fallback messages
    function _anyFallback(
        uint256 fromChainID,
        bytes memory data
    ) internal virtual returns (bool success, bytes memory result);

    /// @dev Send anyCall
    function _anyCall(
        address _to,
        bytes memory _data,
        uint256 _toChainID,
        uint256 fee
    ) internal {
        // reserve 10 percent for fallback
        uint256 fee1 = fee / 10;
        uint256 fee2 = fee - fee1;
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: fee1}(address(this));
        IAnycallProxy(callProxy).anyCall{value: fee2}(
            _to,
            _data,
            _toChainID,
            4,
            ""
        );
    }

    function anyExecute(
        bytes memory data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        (address from, uint256 fromChainID, ) = IAnycallExecutor(
            IAnycallProxy(callProxy).executor()
        ).context();
        require(clientPeers[fromChainID] == from, "AppBase: wrong context");
        return _anyExecute(fromChainID, data);
    }

    function anyFallback(
        bytes calldata data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        (address from, uint256 fromChainID, ) = IAnycallExecutor(
            IAnycallProxy(callProxy).executor()
        ).context();
        require(clientPeers[fromChainID] == from, "AppBase: wrong context");
        return _anyFallback(fromChainID, data);
    }
}

pragma solidity ^0.8.10;

/// IAnycallExecutor interface of the anycall executor
interface IAnycallExecutor {
    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce,
        uint256 _flags,
        bytes calldata _extdata
    ) external returns (bool success, bytes memory result);
}

pragma solidity ^0.8.10;

/// IAnycallProxy interface of the anycall proxy
interface IAnycallProxy {
    function executor() external view returns (address);

    function config() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;
}

pragma solidity ^0.8.10;

interface IFeePool {
    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external view returns (uint256);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BridgeERC20 is ERC20, AccessControl {
    string private _name;
    string private _symbol;
    uint8 _decimals;

    address private _initiator;
    bool public initialized = false;

    constructor() ERC20("", "") {
        _initiator = msg.sender;
    }

    function initERC20(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address admin
    ) public {
        require(_initiator == msg.sender && !initialized);
        initialized = true;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _setRoleAdmin(ROLE_MINTER, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ROLE_BURNER, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function transferAdmin(address to) public {
        _setupRole(DEFAULT_ADMIN_ROLE, to);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    bytes32 ROLE_MINTER = keccak256("role_minter");
    bytes32 ROLE_BURNER = keccak256("role_burner");

    /// @dev only admin
    function setGateway(address _gateway) public {
        grantRole(ROLE_MINTER, _gateway);
        grantRole(ROLE_BURNER, _gateway);
    }

    /// @dev only admin
    function revokeGateway(address _gateway) public {
        revokeRole(ROLE_MINTER, _gateway);
        revokeRole(ROLE_BURNER, _gateway);
    }

    function isGateway(address account) public view returns (bool) {
        return (hasRole(ROLE_MINTER, account) && hasRole(ROLE_BURNER, account));
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount)
        public
        onlyRole(ROLE_MINTER)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        public
        onlyRole(ROLE_BURNER)
    {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ISwapInSafetyControl.sol";

interface IToken {
    function totalSupply() external view virtual returns (uint256);
}

interface IGateway {
    function token() external view virtual returns (address);
}

contract DefaultSwapInSafetyControl is ISwapInSafetyControl {
    mapping(address => bool) public blacklist;
    uint256 public maxSupply;
    uint256 public maxAmountPerTx;
    uint256 public maxAmountPerDay;
    uint256 public lastSwapInDay;
    uint256 public accumulatedAmount;
    bool public initialized;

    constructor() {}

    function initDefaultSafetyControls(
        address safetyAdmin,
        address gateway,
        uint _maxSupply,
        uint _maxAmountPerTx,
        uint _maxAmountPerDay
    ) public {
        require(!initialized);
        initSafetyControl(safetyAdmin, gateway);
        maxSupply = _maxSupply;
        maxAmountPerTx = _maxAmountPerTx;
        maxAmountPerDay = _maxAmountPerDay;
        lastSwapInDay = block.timestamp / 1 days;
        initialized = true;
    }

    function checkSwapIn(
        uint256 fromChainID,
        uint256 amount,
        address receiver
    ) public view virtual override returns (bool) {
        if (blacklist[receiver]) {
            return false;
        }
        if (
            IToken(IGateway(gateway).token()).totalSupply() + amount >=
            maxSupply
        ) {
            return false;
        }
        if (amount > maxAmountPerTx) {
            return false;
        }
        if (
            block.timestamp / 1 days == lastSwapInDay &&
            accumulatedAmount + amount > maxAmountPerDay
        ) {
            return false;
        }
        return true;
    }

    function _update(
        uint256 fromChainID,
        uint256 amount,
        address receiver
    ) internal virtual override {
        if (block.timestamp / 1 days > lastSwapInDay) {
            accumulatedAmount = amount;
        } else {
            accumulatedAmount += amount;
        }
        lastSwapInDay = block.timestamp / 1 days;
    }

    function setBlacklist(address account, bool isBlack) public {
        require(msg.sender == safetyAdmin);
        blacklist[account] = isBlack;
    }

    function setMaxSupply(uint256 amount) public {
        require(msg.sender == safetyAdmin);
        maxSupply = amount;
    }

    function setMaxAmountPerTx(uint256 amount) public {
        require(msg.sender == safetyAdmin);
        maxAmountPerTx = amount;
    }

    function setMaxAmountPerDay(uint256 amount) public {
        require(msg.sender == safetyAdmin);
        maxAmountPerDay = amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC20Gateway.sol";

interface IMintBurn {
    function balanceOf(address account) external returns (uint256);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract ERC20Gateway_MintBurn is ERC20Gateway {
    function description() external pure returns (string memory) {
        return "ERC20Gateway_MintBurn";
    }

    function _swapout(
        uint256 amount,
        address sender
    ) internal override returns (bool) {
        uint256 bal_0 = IMintBurn(token).balanceOf(sender);
        try IMintBurn(token).burn(sender, amount) {
            uint256 bal_1 = IMintBurn(token).balanceOf(sender);
            require(bal_0 - bal_1 >= amount);
            return true;
        } catch {
            return false;
        }
    }

    function _swapin(
        uint256 amount,
        address receiver
    ) internal override returns (bool) {
        try IMintBurn(token).mint(receiver, amount) {
            return true;
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC20Gateway.sol";

interface ITransfer {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWNative {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

contract ERC20Gateway_Pool is ERC20Gateway {
    bool public isWNative;

    function description() external pure returns (string memory) {
        return "ERC20Gateway_Pool";
    }

    function initIsWNative(bool _isWNative) public {
        require(!initialized);
        isWNative = _isWNative;
    }

    function _swapout(
        uint256 amount,
        address sender
    ) internal override returns (bool) {
        if (isWNative && msg.value > 0) {
            if (msg.value < amount) {
                return false;
            }
            IWNative(token).deposit{value: msg.value}();
            return true;
        } else {
            return ITransfer(token).transferFrom(sender, address(this), amount);
        }
    }

    function _swapin(
        uint256 amount,
        address receiver
    ) internal override returns (bool) {
        ITransfer(token).approve(address(this), amount);
        if (isWNative) {
            try IWNative(token).withdraw(amount) {} catch {
                return false;
            }
            (bool succ, ) = receiver.call{value: amount}("");
            return succ;
        } else {
            return
                ITransfer(token).transferFrom(address(this), receiver, amount);
        }
    }

    mapping(address => uint256) public balanceOf;

    event Deposit(address, uint256);
    event Withdraw(address, uint256);

    function deposit(uint256 amount) external {
        bool succ = ITransfer(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(succ);
        balanceOf[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        bool succ = ITransfer(token).transferFrom(
            address(this),
            msg.sender,
            amount
        );
        require(succ);
        emit Withdraw(msg.sender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../AnyCallAppBase/AnyCallApp.sol";
import "./ISwapInSafetyControl.sol";
import "./fee/DFaxFee.sol";

interface IDecimal {
    function decimals() external view returns (uint8);
}

interface IERC20Gateway {
    function token() external view returns (address);

    function Swapout(
        uint256 amount,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256 swapoutSeq);
}

abstract contract ERC20Gateway is IERC20Gateway, AnyCallApp, DFaxFee {
    address public token;
    mapping(uint256 => uint8) public decimals;
    uint256 public swapoutSeq;

    address private _initiator;
    bool public initialized = false;

    ISwapInSafetyControl public safetyControl;

    constructor() DFaxFee() {
        _initiator = msg.sender;
    }

    function initERC20Gateway(
        address anyCallProxy,
        address token_,
        address admin,
        address _safetyControl,
        address dFaxFeeAdmin,
        address defaultFeeScheme
    ) public {
        require(_initiator == msg.sender && !initialized);
        initialized = true;
        token = token_;
        initAnyCallApp(anyCallProxy, admin);
        safetyControl = ISwapInSafetyControl(_safetyControl);
        initDFaxFee(dFaxFeeAdmin, defaultFeeScheme);
    }

    function _swapout(
        uint256 amount,
        address sender
    ) internal virtual returns (bool);

    function _swapin(
        uint256 amount,
        address receiver
    ) internal virtual returns (bool);

    event LogAnySwapOut(
        uint256 amount,
        address sender,
        address receiver,
        uint256 toChainID,
        uint256 swapoutSeq
    );

    function setDecimals(
        uint256[] memory chainIDs,
        uint8[] memory decimals_
    ) external onlyAdmin {
        for (uint256 i = 0; i < chainIDs.length; i++) {
            decimals[chainIDs[i]] = decimals_[i];
        }
    }

    function decimal(uint256 chainID) external view returns (uint8) {
        return (
            decimals[chainID] > 0
                ? decimals[chainID]
                : IDecimal(token).decimals()
        );
    }

    function convertDecimal(
        uint256 amount,
        uint8 d_0
    ) public view returns (uint256) {
        uint8 d_1 = IDecimal(token).decimals();
        if (d_0 > d_1) {
            for (uint8 i = 0; i < (d_0 - d_1); i++) {
                amount = amount / 10;
            }
        } else {
            for (uint8 i = 0; i < (d_1 - d_0); i++) {
                amount = amount * 10;
            }
        }
        return amount;
    }

    function setSatetyControl(address newSafetyControl) external onlyAdmin {
        safetyControl = ISwapInSafetyControl(newSafetyControl);
    }

    function Swapout(
        uint256 amount,
        address receiver,
        uint256 destChainID
    ) external payable returns (uint256) {
        require(_swapout(amount, msg.sender));
        swapoutSeq++;
        bytes memory data = abi.encode(
            amount,
            IDecimal(token).decimals(),
            receiver,
            swapoutSeq
        );
        uint256 dFeeCharged = chargeFee(msg.sender, destChainID, amount);
        uint256 anyCallFee = msg.value - dFeeCharged;
        _anyCall(clientPeers[destChainID], data, destChainID, anyCallFee);
        emit LogAnySwapOut(
            amount,
            msg.sender,
            receiver,
            destChainID,
            swapoutSeq
        );
        return swapoutSeq;
    }

    function _anyExecute(
        uint256 fromChainID,
        bytes memory data
    ) internal override returns (bool success, bytes memory result) {
        (uint256 amount, uint8 _decimals, address receiver, ) = abi.decode(
            data,
            (uint256, uint8, address, uint256)
        );
        amount = convertDecimal(amount, _decimals);
        if (address(safetyControl) != address(0)) {
            require(
                safetyControl.checkSwapIn(fromChainID, amount, receiver),
                "swapin restricted"
            );
        }
        success = _swapin(amount, receiver);
        safetyControl.update(fromChainID, amount, receiver);
    }

    function _anyFallback(
        uint256 fromChainID,
        bytes memory data
    ) internal override returns (bool success, bytes memory result) {
        (uint256 amount, , address originSender, , ) = abi.decode(
            data,
            (uint256, uint8, address, address, uint256)
        );
        success = (_swapin(amount, originSender));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./BridgeERC20.sol";
import "./ERC20Gateway_MintBurn.sol";
import "./ERC20Gateway_Pool.sol";
import "./DefaultSwapInSafetyControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ICodeShop {
    function getCode() external view virtual returns (bytes memory);
}

contract CodeShop_BridgeToken is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(BridgeERC20).creationCode;
    }
}

contract CodeShop_MintBurnGateway is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(ERC20Gateway_MintBurn).creationCode;
    }
}

contract CodeShop_PoolGateway is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(ERC20Gateway_Pool).creationCode;
    }
}

contract CodeShop_DefaultSafetyControl is ICodeShop {
    function getCode() public pure returns (bytes memory) {
        return type(DefaultSwapInSafetyControl).creationCode;
    }
}

contract BridgeFactory is AccessControl {
    address anyCallProxy;
    ICodeShop[4] codeShops;
    address public dfaxFeeAdmin;

    /// @param _codeShops is sort list of CodeShop addresses : `[CS_BridgeToken, CS_MintBurnGateway, CS_PoolGateway, CodeShop_DefaultSafetyControl]`
    constructor(
        address _anyCallProxy,
        address[] memory _codeShops,
        address _dfaxFeeAdmin
    ) {
        require(_codeShops.length == 4);
        anyCallProxy = _anyCallProxy;
        for (uint256 i = 0; i < _codeShops.length; i++) {
            codeShops[i] = ICodeShop(_codeShops[i]);
        }
        dfaxFeeAdmin = _dfaxFeeAdmin;
    }

    event Create(string contractType, address contractAddress);

    function getBridgeTokenAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        bytes memory bytecode = codeShops[0].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getPoolGatewayAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        bytes memory bytecode = codeShops[2].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getMintBurnGatewayAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        bytes memory bytecode = codeShops[1].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function createBridgeToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt
    ) public returns (address) {
        return
            _createBridgeToken(name_, symbol_, decimals_, owner, salt, owner);
    }

    function _createBridgeToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt,
        address admin
    ) internal returns (address) {
        address payable addr;
        bytes memory bytecode = codeShops[0].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 bridge token", addr);
        BridgeERC20(addr).initERC20(name_, symbol_, decimals_, admin);
        return addr;
    }

    function createPoolGateway(
        address token,
        address owner,
        uint256 salt
    ) public returns (address, address) {
        address payable gatewayAddr;
        bytes memory bytecode = codeShops[2].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            gatewayAddr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(gatewayAddr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 pool gateway", gatewayAddr);
        address payable safetyControlAddr;
        bytes memory safetyControlBytecode = codeShops[3].getCode();
        salt = uint256(keccak256(abi.encodePacked(gatewayAddr, owner, salt)));
        assembly {
            safetyControlAddr := create2(
                0,
                add(safetyControlBytecode, 0x20),
                mload(safetyControlBytecode),
                salt
            )

            if iszero(extcodesize(safetyControlAddr)) {
                revert(0, 0)
            }
        }
        emit Create("Default safety control", safetyControlAddr);
        ERC20Gateway(gatewayAddr).initERC20Gateway(
            anyCallProxy,
            token,
            owner,
            safetyControlAddr,
            dfaxFeeAdmin,
            address(0)
        );
        DefaultSwapInSafetyControl(safetyControlAddr).initDefaultSafetyControls(
            owner,
            gatewayAddr,
            (1 << 256) - 1,
            (1 << 256) - 1,
            (1 << 256) - 1
        );
        return (gatewayAddr, safetyControlAddr);
    }

    function createWNativePoolGateway(
        address token,
        address owner,
        uint256 salt
    ) public returns (address, address) {
        address payable gatewayAddr;
        bytes memory bytecode = codeShops[2].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            gatewayAddr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(gatewayAddr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 pool gateway", gatewayAddr);
        address payable safetyControlAddr;
        bytes memory safetyControlBytecode = codeShops[3].getCode();
        salt = uint256(keccak256(abi.encodePacked(gatewayAddr, owner, salt)));
        assembly {
            safetyControlAddr := create2(
                0,
                add(safetyControlBytecode, 0x20),
                mload(safetyControlBytecode),
                salt
            )

            if iszero(extcodesize(safetyControlAddr)) {
                revert(0, 0)
            }
        }
        emit Create("Default safety control", safetyControlAddr);
        ERC20Gateway_Pool(gatewayAddr).initIsWNative(true);
        ERC20Gateway(gatewayAddr).initERC20Gateway(
            anyCallProxy,
            token,
            owner,
            safetyControlAddr,
            dfaxFeeAdmin,
            address(0)
        );
        DefaultSwapInSafetyControl(safetyControlAddr).initDefaultSafetyControls(
            owner,
            gatewayAddr,
            (1 << 256) - 1,
            (1 << 256) - 1,
            (1 << 256) - 1
        );
        return (gatewayAddr, safetyControlAddr);
    }

    function createMintBurnGateway(
        address token,
        address owner,
        uint256 salt
    ) public returns (address, address) {
        address payable gatewayAddr;
        bytes memory bytecode = codeShops[1].getCode();
        salt = uint256(keccak256(abi.encodePacked(owner, salt)));
        assembly {
            gatewayAddr := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(gatewayAddr)) {
                revert(0, 0)
            }
        }
        emit Create("ERC20 mint-burn gateway", gatewayAddr);
        address payable safetyControlAddr;
        bytes memory safetyControlBytecode = codeShops[3].getCode();
        salt = uint256(keccak256(abi.encodePacked(gatewayAddr, owner, salt)));
        assembly {
            safetyControlAddr := create2(
                0,
                add(safetyControlBytecode, 0x20),
                mload(safetyControlBytecode),
                salt
            )

            if iszero(extcodesize(safetyControlAddr)) {
                revert(0, 0)
            }
        }
        emit Create("Default safety control", safetyControlAddr);
        ERC20Gateway(gatewayAddr).initERC20Gateway(
            anyCallProxy,
            token,
            owner,
            safetyControlAddr,
            dfaxFeeAdmin,
            address(0)
        );
        DefaultSwapInSafetyControl(safetyControlAddr).initDefaultSafetyControls(
            owner,
            gatewayAddr,
            (1 << 256) - 1,
            (1 << 256) - 1,
            (1 << 256) - 1
        );
        return (gatewayAddr, safetyControlAddr);
    }

    function createTokenAndMintBurnGateway(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt
    ) public returns (address, address, address) {
        address token = _createBridgeToken(
            name_,
            symbol_,
            decimals_,
            owner,
            salt,
            address(this)
        );
        (address gateway, address safetyControl) = createMintBurnGateway(
            token,
            owner,
            salt
        );
        BridgeERC20(token).setGateway(gateway);
        BridgeERC20(token).transferAdmin(owner);
        return (token, gateway, safetyControl);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IFeeScheme.sol";

contract DFaxFee {
    address public dfaxFeeAdmin;

    address[] public feeOwners;
    uint256[] public feeOwnerAccrued;
    uint256[] public feeOwnerWeights;

    IFeeScheme public feeScheme;

    uint256 internal dFeeCharged;

    modifier onlyDFaxFeeAdmin() {
        require(msg.sender == dfaxFeeAdmin);
        _;
    }

    constructor() {}

    function initDFaxFee(
        address _dFaxFeeAdmin,
        address defaultFeeScheme
    ) internal {
        _setDFaxFeeAdmin(_dFaxFeeAdmin);
        _setFeeScheme(defaultFeeScheme);
    }

    function setDFaxFeeAdmin(address dfaxFeeAdmin) public onlyDFaxFeeAdmin {
        _setDFaxFeeAdmin(dfaxFeeAdmin);
    }

    function _setDFaxFeeAdmin(address _dfaxFeeAdmin) internal {
        dfaxFeeAdmin = _dfaxFeeAdmin;
    }

    function addFeeOwner(
        address feeOwner,
        uint256 weight
    ) public onlyDFaxFeeAdmin {
        for (uint i = 0; i < feeOwners.length; i++) {
            require(feeOwners[i] != feeOwner, "duplicated fee owner address");
        }
        feeOwners.push(feeOwner);
        feeOwnerWeights.push(weight);
    }

    function getFeeOwnerWeight(address feeOwner) public view returns (uint256) {
        for (uint i = 0; i < feeOwners.length; i++) {
            if (feeOwners[i] == feeOwner) {
                return feeOwnerWeights[i];
            }
        }
        return 0;
    }

    function getTotalWeight() public view returns (uint256) {
        uint256 totalWeight;
        for (uint i = 0; i < feeOwners.length; i++) {
            totalWeight += feeOwnerWeights[i];
        }
        return totalWeight;
    }

    function updateFeeOwner(
        address feeOwner,
        uint256 weight
    ) public onlyDFaxFeeAdmin {
        _updateFeeOwner(feeOwner, weight);
    }

    function _updateFeeOwner(
        address feeOwner,
        uint256 weight
    ) public onlyDFaxFeeAdmin {
        for (uint i = 0; i < feeOwners.length; i++) {
            if (feeOwners[i] == feeOwner) {
                feeOwnerWeights[i] = weight;
            }
        }
    }

    function removeFeeOwner(address feeOwner) public onlyDFaxFeeAdmin {
        _updateFeeOwner(feeOwner, 0);
    }

    function setFeeScheme(address feeScheme) public onlyDFaxFeeAdmin {
        _setFeeScheme(feeScheme);
    }

    function _setFeeScheme(address _feeScheme) internal {
        feeScheme = IFeeScheme(_feeScheme);
    }

    function chargeFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) internal returns (uint256) {
        uint256 fee = calcFee(sender, toChainID, amount);
        (bool succ, ) = address(this).call{value: fee}("");
        require(succ, "charge fee failed");

        uint256 totalWeight;
        for (uint i = 0; i < feeOwners.length; i++) {
            totalWeight += feeOwnerWeights[i];
        }
        for (uint i = 0; i < feeOwners.length; i++) {
            feeOwnerAccrued[i] += (fee * feeOwnerWeights[i]) / totalWeight;
        }

        return fee;
    }

    function withdrawDFaxFee(address to, uint256 amount) public {
        uint index = 0;
        for (uint i = 0; i < feeOwners.length; i++) {
            if (feeOwners[i] == msg.sender) {
                index = i;
            }
        }
        require(feeOwnerAccrued[index] >= amount, "amount exceeds fee accrued");
        (bool succ, ) = to.call{value: amount}("");
        require(succ);
        feeOwnerAccrued[index] -= amount;
    }

    function calcFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) public view returns (uint256) {
        if (address(feeScheme) == address(0)) {
            return 0;
        }
        return feeScheme.calcFee(sender, toChainID, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFeeScheme {
    function calcFee(
        address sender,
        uint256 toChainID,
        uint256 amount
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract ISwapInSafetyControl {
    address safetyAdmin;
    address gateway;

    function initSafetyControl(
        address _safetyAdmin,
        address _gateway
    ) internal {
        setSafetyAdmin(_safetyAdmin);
        gateway = _gateway;
    }

    function checkSwapIn(
        uint256 fromChainID,
        uint256 amount,
        address receiver
    ) public view virtual returns (bool);

    function update(
        uint256 fromChainID,
        uint256 amount,
        address receiver
    ) public {
        require(msg.sender == gateway);
        _update(fromChainID, amount, receiver);
    }

    function _update(
        uint256 fromChainID,
        uint256 amount,
        address receiver
    ) internal virtual;

    function setSafetyAdmin(address _admin) internal virtual {
        safetyAdmin = _admin;
    }

    function changeAdmin(address to) public {
        require(msg.sender == safetyAdmin);
        safetyAdmin = to;
    }
}