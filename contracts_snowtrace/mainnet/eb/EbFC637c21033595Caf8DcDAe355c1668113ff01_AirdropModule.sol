// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

interface IController {
  function addDomani(address _domani) external;

  function feeRecipient() external view returns (address);

  function getModuleFee(address _module, uint256 _feeType) external view returns (uint256);

  function isModule(address _module) external view returns (bool);

  function isDomani(address _domani) external view returns (bool);

  function isSystemContract(address _contractAddress) external view returns (bool);

  function resourceId(uint256 _id) external view returns (address);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IDomani
 * @author Domani Protocol
 *
 * Interface for operating with Domani tokens.
 */
interface IDomani is IERC20 {
  /* ============ Enums ============ */

  enum ModuleState {
    NONE,
    PENDING,
    INITIALIZED
  }

  /* ============ Structs ============ */
  /**
   * The base definition of a Domani Position
   *
   * @param component           Address of token in the Position
   * @param module              If not in default state, the address of associated module
   * @param unit                Each unit is the # of components per 10^18 of a Domani token
   * @param positionState       Position ENUM. Default is 0; External is 1
   * @param data                Arbitrary data
   */
  struct Position {
    address component;
    address module;
    int256 unit;
    uint8 positionState;
    bytes data;
  }

  /**
   * A struct that stores a component's cash position details and external positions
   * This data structure allows O(1) access to a component's cash position units and
   * virtual units.
   *
   * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
   *                                  updating all units at once via the position multiplier. Virtual units are achieved
   *                                  by dividing a "real" value by the "positionMultiplier"
   * @param componentIndex
   * @param externalPositionModules   List of external modules attached to each external position. Each module
   *                                  maps to an external position
   * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
   */
  struct ComponentPosition {
    int256 virtualUnit;
    address[] externalPositionModules;
    mapping(address => ExternalPosition) externalPositions;
  }

  /**
   * A struct that stores a component's external position details including virtual unit and any
   * auxiliary data.
   *
   * @param virtualUnit       Virtual value of a component's EXTERNAL position.
   * @param data              Arbitrary data
   */
  struct ExternalPosition {
    int256 virtualUnit;
    bytes data;
  }

  /* ============ Functions ============ */

  function addComponent(address _component) external;

  function removeComponent(address _component) external;

  function editDefaultPositionUnit(address _component, int256 _realUnit) external;

  function addExternalPositionModule(address _component, address _positionModule) external;

  function removeExternalPositionModule(address _component, address _positionModule) external;

  function editExternalPositionUnit(
    address _component,
    address _positionModule,
    int256 _realUnit
  ) external;

  function editExternalPositionData(
    address _component,
    address _positionModule,
    bytes calldata _data
  ) external;

  function invoke(
    address _target,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes memory);

  function editPositionMultiplier(int256 _newMultiplier) external;

  function mint(address _account, uint256 _quantity) external;

  function burn(address _account, uint256 _quantity) external;

  function lock() external;

  function unlock() external;

  function addModule(address _module) external;

  function removeModule(address _module) external;

  function initializeModule() external;

  function setManager(address _manager) external;

  function manager() external view returns (address);

  function moduleStates(address _module) external view returns (ModuleState);

  function getModules() external view returns (address[] memory);

  function getDefaultPositionRealUnit(address _component) external view returns (int256);

  function getExternalPositionRealUnit(address _component, address _positionModule)
    external
    view
    returns (int256);

  function getComponents() external view returns (address[] memory);

  function getExternalPositionModules(address _component) external view returns (address[] memory);

  function getExternalPositionData(address _component, address _positionModule)
    external
    view
    returns (bytes memory);

  function isExternalPositionModule(address _component, address _module)
    external
    view
    returns (bool);

  function isComponent(address _component) external view returns (bool);

  function positionMultiplier() external view returns (int256);

  function getPositions() external view returns (Position[] memory);

  function getTotalComponentRealUnits(address _component) external view returns (int256);

  function isInitializedModule(address _module) external view returns (bool);

  function isPendingModule(address _module) external view returns (bool);

  function isLocked() external view returns (bool);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

import {IDomani} from "../interfaces/IDomani.sol";

interface IDomaniValuer {
  function calculateDomaniValuation(IDomani _domani, address _quoteAsset)
    external
    view
    returns (uint256);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

interface IIntegrationRegistry {
  function addIntegration(
    address _module,
    string memory _id,
    address _wrapper
  ) external;

  function getIntegrationAdapter(address _module, string memory _id)
    external
    view
    returns (address);

  function getIntegrationAdapterWithHash(address _module, bytes32 _id)
    external
    view
    returns (address);

  function isValidIntegration(address _module, string memory _id) external view returns (bool);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

/**
 * @title IModule
 * @author Domani Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
  /**
   * Called by a Domani to notify that this module was removed from the Domani token. Any logic can be included
   * in case checks need to be made or state needs to be cleared.
   */
  function removeModule() external;
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;

/**
 * @title IPriceOracle
 * @author Domani Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
  /* ============ Functions ============ */

  function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);

  function masterQuoteAsset() external view returns (address);
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

/**
 * @title AddressArrayUtils
 * @author Domani Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/21/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {
  /**
   * Finds the index of the first occurrence of the given element.
   * @param A The input array to search
   * @param a The value to find
   * @return Returns (index and isIn) for the first occurrence starting from index 0
   */
  function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
    uint256 length = A.length;
    for (uint256 i = 0; i < length; i++) {
      if (A[i] == a) {
        return (i, true);
      }
    }
    return (uint256(-1), false);
  }

  /**
   * Returns true if the value is present in the list. Uses indexOf internally.
   * @param A The input array to search
   * @param a The value to find
   * @return Returns isIn for the first occurrence starting from index 0
   */
  function contains(address[] memory A, address a) internal pure returns (bool) {
    (, bool isIn) = indexOf(A, a);
    return isIn;
  }

  /**
   * Returns true if there are 2 elements that are the same in an array
   * @param A The input array to search
   * @return Returns boolean for the first occurrence of a duplicate
   */
  function hasDuplicate(address[] memory A) internal pure returns (bool) {
    require(A.length > 0, "A is empty");

    for (uint256 i = 0; i < A.length - 1; i++) {
      address current = A[i];
      for (uint256 j = i + 1; j < A.length; j++) {
        if (current == A[j]) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * @param A The input array to search
   * @param a The address to remove
   * @return Returns the array with the object removed.
   */
  function remove(address[] memory A, address a) internal pure returns (address[] memory) {
    (uint256 index, bool isIn) = indexOf(A, a);
    if (!isIn) {
      revert("Address not in array.");
    } else {
      (address[] memory _A, ) = pop(A, index);
      return _A;
    }
  }

  /**
   * @param A The input array to search
   * @param a The address to remove
   */
  function removeStorage(address[] storage A, address a) internal {
    (uint256 index, bool isIn) = indexOf(A, a);
    if (!isIn) {
      revert("Address not in array.");
    } else {
      uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
      if (index != lastIndex) {
        A[index] = A[lastIndex];
      }
      A.pop();
    }
  }

  /**
   * Removes specified index from array
   * @param A The input array to search
   * @param index The index to remove
   * @return Returns the new array and the removed entry
   */
  function pop(address[] memory A, uint256 index)
    internal
    pure
    returns (address[] memory, address)
  {
    uint256 length = A.length;
    require(index < A.length, "Index must be < A length");
    address[] memory newAddresses = new address[](length - 1);
    for (uint256 i = 0; i < index; i++) {
      newAddresses[i] = A[i];
    }
    for (uint256 j = index + 1; j < length; j++) {
      newAddresses[j - 1] = A[j];
    }
    return (newAddresses, A[index]);
  }

  /**
   * Returns the combination of the two arrays
   * @param A The first array
   * @param B The second array
   * @return Returns A extended by B
   */
  function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
    uint256 aLength = A.length;
    uint256 bLength = B.length;
    address[] memory newAddresses = new address[](aLength + bLength);
    for (uint256 i = 0; i < aLength; i++) {
      newAddresses[i] = A[i];
    }
    for (uint256 j = 0; j < bLength; j++) {
      newAddresses[aLength + j] = B[j];
    }
    return newAddresses;
  }

  /**
   * Validate that address and uint array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of uint
   */
  function validatePairsWithArray(address[] memory A, uint256[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and bool array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of bool
   */
  function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and string array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of strings
   */
  function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address array lengths match, and calling address array are not empty
   * and contain no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of addresses
   */
  function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and bytes array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of bytes
   */
  function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate address array is not empty and contains no duplicate elements.
   *
   * @param A          Array of addresses
   */
  function _validateLengthAndUniqueness(address[] memory A) internal pure {
    require(A.length > 0, "Array length must be > 0");
    require(!hasDuplicate(A), "Cannot duplicate addresses");
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Domani Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
  using SafeMath for uint256;

  /**
   * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
   * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
   *
   * @param _token           ERC20 token to approve
   * @param _from            The account to transfer tokens from
   * @param _to              The account to transfer tokens to
   * @param _quantity        The quantity to transfer
   */
  function transferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _quantity
  ) internal {
    // Call specified ERC20 contract to transfer tokens (via proxy).
    if (_quantity > 0) {
      uint256 existingBalance = _token.balanceOf(_to);

      SafeERC20.safeTransferFrom(_token, _from, _to, _quantity);

      uint256 newBalance = _token.balanceOf(_to);

      // Verify transfer quantity is reflected in balance
      require(newBalance == existingBalance.add(_quantity), "Invalid post transfer balance");
    }
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title PreciseUnitMath
 * @author Domani Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 */
library PreciseUnitMath {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;
  int256 internal constant PRECISE_UNIT_INT = 10**18;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;
  // Max and min signed integer value
  int256 internal constant MAX_INT_256 = type(int256).max;
  int256 internal constant MIN_INT_256 = type(int256).min;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnitInt() internal pure returns (int256) {
    return PRECISE_UNIT_INT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxInt256() internal pure returns (int256) {
    return MAX_INT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function minInt256() internal pure returns (int256) {
    return MIN_INT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b).div(PRECISE_UNIT);
  }

  /**
   * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
   * significand of a number with 18 decimals precision.
   */
  function preciseMul(int256 a, int256 b) internal pure returns (int256) {
    return a.mul(b).div(PRECISE_UNIT_INT);
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(PRECISE_UNIT).div(b);
  }

  /**
   * @dev Divides value a by value b (result is rounded towards 0).
   */
  function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
    return a.mul(PRECISE_UNIT_INT).div(b);
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Cant divide by 0");

    return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
  }

  /**
   * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
   */
  function divDown(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "Cant divide by 0");
    require(a != MIN_INT_256 || b != -1, "Invalid input");

    int256 result = a.div(b);
    if (a ^ b < 0 && a % b != 0) {
      result -= 1;
    }

    return result;
  }

  /**
   * @dev Multiplies value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a.mul(b), PRECISE_UNIT_INT);
  }

  /**
   * @dev Divides value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a.mul(PRECISE_UNIT_INT), b);
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, "Value must be positive");

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      // Using safemath multiplication prevents overflows
      result = previousResult.mul(a);
    }

    return result;
  }

  /**
   * @dev Returns true if a =~ b within range, false otherwise.
   */
  function approximatelyEquals(
    uint256 a,
    uint256 b,
    uint256 range
  ) internal pure returns (bool) {
    return a <= b.add(range) && a >= b.sub(range);
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IDomani} from "../../interfaces/IDomani.sol";

/**
 * @title Invoke
 * @author Domani Protocol
 *
 * A collection of common utility functions for interacting with the Domani's invoke function
 */
library Invoke {
  using SafeMath for uint256;

  /* ============ Internal ============ */

  /**
   * Instructs the Domani to domani approvals of the ERC20 token to a spender.
   *
   * @param _domani        Domani instance to invoke
   * @param _token           ERC20 token to approve
   * @param _spender         The account allowed to spend the Domani's balance
   * @param _quantity        The quantity of allowance to allow
   */
  function invokeApprove(
    IDomani _domani,
    address _token,
    address _spender,
    uint256 _quantity
  ) internal {
    bytes memory callData = abi.encodeWithSignature(
      "approve(address,uint256)",
      _spender,
      _quantity
    );
    _domani.invoke(_token, 0, callData);
  }

  /**
   * Instructs the Domani to transfer the ERC20 token to a recipient.
   *
   * @param _domani        Domani instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function invokeTransfer(
    IDomani _domani,
    address _token,
    address _to,
    uint256 _quantity
  ) internal {
    if (_quantity > 0) {
      bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
      _domani.invoke(_token, 0, callData);
    }
  }

  /**
   * Instructs the Domani to transfer the ERC20 token to a recipient.
   * The new Domani balance must equal the existing balance less the quantity transferred
   *
   * @param _domani        Domani instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function strictInvokeTransfer(
    IDomani _domani,
    address _token,
    address _to,
    uint256 _quantity
  ) internal {
    if (_quantity > 0) {
      // Retrieve current balance of token for the Domani
      uint256 existingBalance = IERC20(_token).balanceOf(address(_domani));

      Invoke.invokeTransfer(_domani, _token, _to, _quantity);

      // Get new balance of transferred token for Domani
      uint256 newBalance = IERC20(_token).balanceOf(address(_domani));

      // Verify only the transfer quantity is subtracted
      require(newBalance == existingBalance.sub(_quantity), "Invalid post transfer balance");
    }
  }

  /**
   * Instructs the Domani to unwrap the passed quantity of WETH
   *
   * @param _domani        Domani instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeUnwrapWETH(
    IDomani _domani,
    address _weth,
    uint256 _quantity
  ) internal {
    bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
    _domani.invoke(_weth, 0, callData);
  }

  /**
   * Instructs the Domani to wrap the passed quantity of ETH
   *
   * @param _domani        Domani instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeWrapWETH(
    IDomani _domani,
    address _weth,
    uint256 _quantity
  ) internal {
    bytes memory callData = abi.encodeWithSignature("deposit()");
    _domani.invoke(_weth, _quantity, callData);
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AddressArrayUtils} from "../../lib/AddressArrayUtils.sol";
import {ExplicitERC20} from "../../lib/ExplicitERC20.sol";
import {IController} from "../../interfaces/IController.sol";
import {IModule} from "../../interfaces/IModule.sol";
import {IDomani} from "../../interfaces/IDomani.sol";
import {Invoke} from "./Invoke.sol";
import {Position} from "./Position.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";
import {ResourceIdentifier} from "./ResourceIdentifier.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Domani Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
  using AddressArrayUtils for address[];
  using Invoke for IDomani;
  using Position for IDomani;
  using PreciseUnitMath for uint256;
  using ResourceIdentifier for IController;
  using SafeCast for int256;
  using SafeCast for uint256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  /* ============ State Variables ============ */

  // Address of the controller
  IController public controller;

  /* ============ Modifiers ============ */

  modifier onlyManagerAndValidDomani(IDomani _domani) {
    _validateOnlyManagerAndValidDomani(_domani);
    _;
  }

  modifier onlyDomaniManager(IDomani _domani, address _caller) {
    _validateOnlyDomaniManager(_domani, _caller);
    _;
  }

  modifier onlyValidAndInitializedDomani(IDomani _domani) {
    _validateOnlyValidAndInitializedDomani(_domani);
    _;
  }

  /**
   * Throws if the sender is not a Domani's module or module not enabled
   */
  modifier onlyModule(IDomani _domani) {
    _validateOnlyModule(_domani);
    _;
  }

  /**
   * Utilized during module initializations to check that the module is in pending state
   * and that the Domani is valid
   */
  modifier onlyValidAndPendingDomani(IDomani _domani) {
    _validateOnlyValidAndPendingDomani(_domani);
    _;
  }

  /* ============ Constructor ============ */

  /**
   * Domani state variables and map asset pairs to their oracles
   *
   * @param _controller             Address of controller contract
   */
  constructor(IController _controller) {
    controller = _controller;
  }

  /* ============ Internal Functions ============ */

  /**
   * Transfers tokens from an address (that has domani allowance on the module).
   *
   * @param  _token          The address of the ERC20 token
   * @param  _from           The address to transfer from
   * @param  _to             The address to transfer to
   * @param  _quantity       The number of tokens to transfer
   */
  function transferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _quantity
  ) internal {
    ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
  }

  /**
   * Gets the integration for the module with the passed in name. Validates that the address is not empty
   */
  function getAndValidateAdapter(string memory _integrationName) internal view returns (address) {
    bytes32 integrationHash = getNameHash(_integrationName);
    return getAndValidateAdapterWithHash(integrationHash);
  }

  /**
   * Gets the integration for the module with the passed in hash. Validates that the address is not empty
   */
  function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns (address) {
    address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
      address(this),
      _integrationHash
    );

    require(adapter != address(0), "Must be valid adapter");
    return adapter;
  }

  /**
   * Gets the total fee for this module of the passed in index (fee % * quantity)
   */
  function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns (uint256) {
    uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
    return _quantity.preciseMul(feePercentage);
  }

  /**
   * Pays the _feeQuantity from the _domani denominated in _token to the protocol fee recipient
   */
  function payProtocolFeeFromDomani(
    IDomani _domani,
    address _token,
    uint256 _feeQuantity
  ) internal {
    if (_feeQuantity > 0) {
      _domani.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity);
    }
  }

  /**
   * Returns true if the module is in process of initialization on the Domani
   */
  function isDomaniPendingInitialization(IDomani _domani) internal view returns (bool) {
    return _domani.isPendingModule(address(this));
  }

  /**
   * Returns true if the address is the Domani's manager
   */
  function isDomaniManager(IDomani _domani, address _toCheck) internal view returns (bool) {
    return _domani.manager() == _toCheck;
  }

  /**
   * Returns true if Domani must be enabled on the controller
   * and module is registered on the Domani
   */
  function isDomaniValidAndInitialized(IDomani _domani) internal view returns (bool) {
    return controller.isDomani(address(_domani)) && _domani.isInitializedModule(address(this));
  }

  /**
   * Hashes the string and returns a bytes32 value
   */
  function getNameHash(string memory _name) internal pure returns (bytes32) {
    return keccak256(bytes(_name));
  }

  /* ============== Modifier Helpers ===============
   * Internal functions used to reduce bytecode size
   */

  /**
   * Caller must Domani manager and Domani must be valid and initialized
   */
  function _validateOnlyManagerAndValidDomani(IDomani _domani) internal view {
    require(isDomaniManager(_domani, msg.sender), "Must be the Domani manager");
    require(isDomaniValidAndInitialized(_domani), "Must be a valid and initialized Domani");
  }

  /**
   * Caller must Domani manager
   */
  function _validateOnlyDomaniManager(IDomani _domani, address _caller) internal view {
    require(isDomaniManager(_domani, _caller), "Must be the Domani manager");
  }

  /**
   * Domani must be valid and initialized
   */
  function _validateOnlyValidAndInitializedDomani(IDomani _domani) internal view {
    require(isDomaniValidAndInitialized(_domani), "Must be a valid and initialized Domani");
  }

  /**
   * Caller must be initialized module and module must be enabled on the controller
   */
  function _validateOnlyModule(IDomani _domani) internal view {
    require(
      _domani.moduleStates(msg.sender) == IDomani.ModuleState.INITIALIZED,
      "Only the module can call"
    );

    require(controller.isModule(msg.sender), "Module must be enabled on controller");
  }

  /**
   * Domani must be in a pending state and module must be in pending state
   */
  function _validateOnlyValidAndPendingDomani(IDomani _domani) internal view {
    require(controller.isDomani(address(_domani)), "Must be controller-enabled Domani");
    require(isDomaniPendingInitialization(_domani), "Must be pending initialization");
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {IDomani} from "../../interfaces/IDomani.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title Position
 * @author Domani Protocol
 *
 * Collection of helper functions for handling and updating Domani Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
  using SafeCast for uint256;
  using SafeMath for uint256;
  using SafeCast for int256;
  using SignedSafeMath for int256;
  using PreciseUnitMath for uint256;

  /* ============ Helper ============ */

  /**
   * Returns whether the Domani has a default position for a given component (if the real unit is > 0)
   */
  function hasDefaultPosition(IDomani _domani, address _component) internal view returns (bool) {
    return _domani.getDefaultPositionRealUnit(_component) > 0;
  }

  /**
   * Returns whether the Domani has an external position for a given component (if # of position modules is > 0)
   */
  function hasExternalPosition(IDomani _domani, address _component) internal view returns (bool) {
    return _domani.getExternalPositionModules(_component).length > 0;
  }

  /**
   * Returns whether the Domani component default position real unit is greater than or equal to units passed in.
   */
  function hasSufficientDefaultUnits(
    IDomani _domani,
    address _component,
    uint256 _unit
  ) internal view returns (bool) {
    return _domani.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
  }

  /**
   * Returns whether the Domani component external position is greater than or equal to the real units passed in.
   */
  function hasSufficientExternalUnits(
    IDomani _domani,
    address _component,
    address _positionModule,
    uint256 _unit
  ) internal view returns (bool) {
    return _domani.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();
  }

  /**
   * If the position does not exist, create a new Position and add to the Domani. If it already exists,
   * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
   * components where needed (in light of potential external positions).
   *
   * @param _domani           Address of Domani being modified
   * @param _component          Address of the component
   * @param _newUnit            Quantity of Position units - must be >= 0
   */
  function editDefaultPosition(
    IDomani _domani,
    address _component,
    uint256 _newUnit
  ) internal {
    bool isPositionFound = hasDefaultPosition(_domani, _component);
    if (!isPositionFound && _newUnit > 0) {
      // If there is no Default Position and no External Modules, then component does not exist
      if (!hasExternalPosition(_domani, _component)) {
        _domani.addComponent(_component);
      }
    } else if (isPositionFound && _newUnit == 0) {
      // If there is a Default Position and no external positions, remove the component
      if (!hasExternalPosition(_domani, _component)) {
        _domani.removeComponent(_component);
      }
    }

    _domani.editDefaultPositionUnit(_component, _newUnit.toInt256());
  }

  /**
   * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
   * 1) If component is not already added then add component and external position.
   * 2) If component is added but no existing external position using the passed module exists then add the external position.
   * 3) If the existing position is being added to then just update the unit and data
   * 4) If the position is being closed and no other external positions or default positions are associated with the component
   *    then untrack the component and remove external position.
   * 5) If the position is being closed and other existing positions still exist for the component then just remove the
   *    external position.
   *
   * @param _domani         Domani being updated
   * @param _component        Component position being updated
   * @param _module           Module external position is associated with
   * @param _newUnit          Position units of new external position
   * @param _data             Arbitrary data associated with the position
   */
  function editExternalPosition(
    IDomani _domani,
    address _component,
    address _module,
    int256 _newUnit,
    bytes memory _data
  ) internal {
    if (_newUnit != 0) {
      if (!_domani.isComponent(_component)) {
        _domani.addComponent(_component);
        _domani.addExternalPositionModule(_component, _module);
      } else if (!_domani.isExternalPositionModule(_component, _module)) {
        _domani.addExternalPositionModule(_component, _module);
      }
      _domani.editExternalPositionUnit(_component, _module, _newUnit);
      _domani.editExternalPositionData(_component, _module, _data);
    } else {
      require(_data.length == 0, "Passed data must be null");
      // If no default or external position remaining then remove component from components array
      if (_domani.getExternalPositionRealUnit(_component, _module) != 0) {
        address[] memory positionModules = _domani.getExternalPositionModules(_component);
        if (_domani.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
          require(
            positionModules[0] == _module,
            "External positions must be 0 to remove component"
          );
          _domani.removeComponent(_component);
        }
        _domani.removeExternalPositionModule(_component, _module);
      }
    }
  }

  /**
   * Get total notional amount of Default position
   *
   * @param _domaniSupply     Supply of Domani in precise units (10^18)
   * @param _positionUnit       Quantity of Position units
   *
   * @return                    Total notional amount of units
   */
  function getDefaultTotalNotional(uint256 _domaniSupply, uint256 _positionUnit)
    internal
    pure
    returns (uint256)
  {
    return _domaniSupply.preciseMul(_positionUnit);
  }

  /**
   * Get position unit from total notional amount
   *
   * @param _domaniSupply     Supply of Domani in precise units (10^18)
   * @param _totalNotional      Total notional amount of component prior to
   * @return                    Default position unit
   */
  function getDefaultPositionUnit(uint256 _domaniSupply, uint256 _totalNotional)
    internal
    pure
    returns (uint256)
  {
    return _totalNotional.preciseDiv(_domaniSupply);
  }

  /**
   * Get the total tracked balance - total supply * position unit
   *
   * @param _domani           Address of the Domani
   * @param _component          Address of the component
   * @return                    Notional tracked balance
   */
  function getDefaultTrackedBalance(IDomani _domani, address _component)
    internal
    view
    returns (uint256)
  {
    int256 positionUnit = _domani.getDefaultPositionRealUnit(_component);
    return _domani.totalSupply().preciseMul(positionUnit.toUint256());
  }

  /**
   * Calculates the new default position unit and performs the edit with the new unit
   *
   * @param _domani                 Address of the Domani
   * @param _component                Address of the component
   * @param _setTotalSupply           Current Domani supply
   * @param _componentPreviousBalance Pre-action component balance
   * @return                          Current component balance
   * @return                          Previous position unit
   * @return                          New position unit
   */
  function calculateAndEditDefaultPosition(
    IDomani _domani,
    address _component,
    uint256 _setTotalSupply,
    uint256 _componentPreviousBalance
  )
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 currentBalance = IERC20(_component).balanceOf(address(_domani));
    uint256 positionUnit = _domani.getDefaultPositionRealUnit(_component).toUint256();

    uint256 newTokenUnit;
    if (currentBalance > 0) {
      newTokenUnit = calculateDefaultEditPositionUnit(
        _setTotalSupply,
        _componentPreviousBalance,
        currentBalance,
        positionUnit
      );
    } else {
      newTokenUnit = 0;
    }

    editDefaultPosition(_domani, _component, newTokenUnit);

    return (currentBalance, positionUnit, newTokenUnit);
  }

  /**
   * Calculate the new position unit given total notional values pre and post executing an action that changes Domani state
   * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
   *
   * @param _domaniSupply     Supply of Domani in precise units (10^18)
   * @param _preTotalNotional   Total notional amount of component prior to executing action
   * @param _postTotalNotional  Total notional amount of component after the executing action
   * @param _prePositionUnit    Position unit of Domani prior to executing action
   * @return                    New position unit
   */
  function calculateDefaultEditPositionUnit(
    uint256 _domaniSupply,
    uint256 _preTotalNotional,
    uint256 _postTotalNotional,
    uint256 _prePositionUnit
  ) internal pure returns (uint256) {
    // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
    uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_domaniSupply));
    return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_domaniSupply);
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IController} from "../../interfaces/IController.sol";
import {IIntegrationRegistry} from "../../interfaces/IIntegrationRegistry.sol";
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {IDomaniValuer} from "../../interfaces/IDomaniValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Domani Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {
  // IntegrationRegistry will always be resource ID 0 in the system
  uint256 internal constant INTEGRATION_REGISTRY_RESOURCE_ID = 0;
  // PriceOracle will always be resource ID 1 in the system
  uint256 internal constant PRICE_ORACLE_RESOURCE_ID = 1;
  // DomaniValuer resource will always be resource ID 2 in the system
  uint256 internal constant SET_VALUER_RESOURCE_ID = 2;

  /* ============ Internal ============ */

  /**
   * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
   * the Controller
   */
  function getIntegrationRegistry(IController _controller)
    internal
    view
    returns (IIntegrationRegistry)
  {
    return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
  }

  /**
   * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
   */
  function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
    return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
  }

  /**
   * Gets the instance of Domani valuer on Controller. Note: DomaniValuer is stored as index 2 on the Controller
   */
  function getDomaniValuer(IController _controller) internal view returns (IDomaniValuer) {
    return IDomaniValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
  }
}

/*
    Copyright 2020 Domani Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
pragma experimental "ABIEncoderV2";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {AddressArrayUtils} from "../../lib/AddressArrayUtils.sol";
import {IController} from "../../interfaces/IController.sol";
import {IDomani} from "../../interfaces/IDomani.sol";
import {Invoke} from "../lib/Invoke.sol";
import {ModuleBase} from "../lib/ModuleBase.sol";
import {Position} from "../lib/Position.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title AirdropModule
 * @author Domani Protocol
 *
 * Module that enables managers to absorb tokens sent to the Domani into the token's positions. With each Domani,
 * managers are able to specify 1) the airdrops they want to include, 2) an airdrop fee recipient, 3) airdrop fee,
 * and 4) whether all users are allowed to trigger an airdrop.
 */
contract AirdropModule is ModuleBase, ReentrancyGuard {
  using PreciseUnitMath for uint256;
  using SafeMath for uint256;
  using Position for uint256;
  using SafeCast for int256;
  using AddressArrayUtils for address[];
  using Invoke for IDomani;
  using Position for IDomani;

  /* ============ Structs ============ */

  struct AirdropSettings {
    address[] airdrops; // Array of tokens manager is allowing to be absorbed
    address feeRecipient; // Address airdrop fees are sent to
    uint256 airdropFee; // Percentage in preciseUnits of airdrop sent to feeRecipient (1e16 = 1%)
    bool anyoneAbsorb; // Boolean indicating if any address can call absorb or just the manager
  }

  /* ============ Events ============ */

  event ComponentAbsorbed(
    IDomani indexed _domani,
    address _absorbedToken,
    uint256 _absorbedQuantity,
    uint256 _managerFee,
    uint256 _protocolFee
  );

  /* ============ Modifiers ============ */

  /**
   * Throws if claim is confined to the manager and caller is not the manager
   */
  modifier onlyValidCaller(IDomani _domani) {
    require(_isValidCaller(_domani), "Must be valid caller");
    _;
  }

  /* ============ Constants ============ */

  uint256 public constant AIRDROP_MODULE_PROTOCOL_FEE_INDEX = 0;

  /* ============ State Variables ============ */

  mapping(IDomani => AirdropSettings) public airdropSettings;

  /* ============ Constructor ============ */

  // solhint-disable-next-line no-empty-blocks
  constructor(IController _controller) ModuleBase(_controller) {}

  /* ============ External Functions ============ */

  /**
   * Absorb passed tokens into respective positions. If airdropFee defined, send portion to feeRecipient and portion to
   * protocol feeRecipient address. Callable only by manager unless manager has set anyoneAbsorb to true.
   *
   * @param _domani                 Address of Domani
   * @param _tokens                   Array of tokens to absorb
   */
  function batchAbsorb(IDomani _domani, address[] memory _tokens)
    external
    nonReentrant
    onlyValidCaller(_domani)
    onlyValidAndInitializedDomani(_domani)
  {
    _batchAbsorb(_domani, _tokens);
  }

  /**
   * Absorb specified token into position. If airdropFee defined, send portion to feeRecipient and portion to
   * protocol feeRecipient address. Callable only by manager unless manager has set anyoneAbsorb to true.
   *
   * @param _domani                 Address of Domani
   * @param _token                    Address of token to absorb
   */
  function absorb(IDomani _domani, address _token)
    external
    nonReentrant
    onlyValidCaller(_domani)
    onlyValidAndInitializedDomani(_domani)
  {
    _absorb(_domani, _token);
  }

  /**
   * SET MANAGER ONLY. Adds new tokens to be added to positions when absorb is called.
   *
   * @param _domani                 Address of Domani
   * @param _airdrop                  List of airdrops to add
   */
  function addAirdrop(IDomani _domani, address _airdrop)
    external
    onlyManagerAndValidDomani(_domani)
  {
    require(!isAirdropToken(_domani, _airdrop), "Token already added.");
    airdropSettings[_domani].airdrops.push(_airdrop);
  }

  /**
   * SET MANAGER ONLY. Removes tokens from list to be absorbed.
   *
   * @param _domani                 Address of Domani
   * @param _airdrop                  List of airdrops to remove
   */
  function removeAirdrop(IDomani _domani, address _airdrop)
    external
    onlyManagerAndValidDomani(_domani)
  {
    require(isAirdropToken(_domani, _airdrop), "Token not added.");
    airdropSettings[_domani].airdrops = airdropSettings[_domani].airdrops.remove(_airdrop);
  }

  /**
   * SET MANAGER ONLY. Update whether manager allows other addresses to call absorb.
   *
   * @param _domani                 Address of Domani
   */
  function updateAnyoneAbsorb(IDomani _domani) external onlyManagerAndValidDomani(_domani) {
    airdropSettings[_domani].anyoneAbsorb = !airdropSettings[_domani].anyoneAbsorb;
  }

  /**
   * SET MANAGER ONLY. Update address manager fees are sent to.
   *
   * @param _domani             Address of Domani
   * @param _newFeeRecipient      Address of new fee recipient
   */
  function updateFeeRecipient(IDomani _domani, address _newFeeRecipient)
    external
    onlyDomaniManager(_domani, msg.sender)
    onlyValidAndInitializedDomani(_domani)
  {
    require(_newFeeRecipient != address(0), "Passed address must be non-zero");
    airdropSettings[_domani].feeRecipient = _newFeeRecipient;
  }

  /**
   * SET MANAGER ONLY. Update airdrop fee percentage.
   *
   * @param _domani         Address of Domani
   * @param _newFee           Percentage, in preciseUnits, of new airdrop fee (1e16 = 1%)
   */
  function updateAirdropFee(IDomani _domani, uint256 _newFee)
    external
    onlyDomaniManager(_domani, msg.sender)
    onlyValidAndInitializedDomani(_domani)
  {
    require(_newFee < PreciseUnitMath.preciseUnit(), "Airdrop fee can't exceed 100%");

    // Absorb all outstanding tokens before fee is updated
    _batchAbsorb(_domani, airdropSettings[_domani].airdrops);

    airdropSettings[_domani].airdropFee = _newFee;
  }

  /**
   * SET MANAGER ONLY. Initialize module with Domani and set initial airdrop tokens as well as specify
   * whether anyone can call absorb.
   *
   * @param _domani                 Address of Domani
   * @param _airdropSettings          Struct of airdrop setting for Domani including accepted airdrops, feeRecipient,
   *                                  airdropFee, and indicating if anyone can call an absorb
   */
  function initialize(IDomani _domani, AirdropSettings memory _airdropSettings)
    external
    onlyDomaniManager(_domani, msg.sender)
    onlyValidAndPendingDomani(_domani)
  {
    require(_airdropSettings.airdrops.length > 0, "At least one token must be passed.");
    require(_airdropSettings.airdropFee <= PreciseUnitMath.preciseUnit(), "Fee must be <= 100%.");

    airdropSettings[_domani] = _airdropSettings;

    _domani.initializeModule();
  }

  /**
   * Removes this module from the Domani, via call by the Domani. Token's airdrop settings are deleted.
   * Airdrops are not absorbed.
   */
  function removeModule() external override {
    delete airdropSettings[IDomani(msg.sender)];
  }

  /**
   * Get list of tokens approved to collect airdrops for the Domani.
   *
   * @param _domani             Address of Domani
   * @return                      Array of tokens approved for airdrops
   */
  function getAirdrops(IDomani _domani) external view returns (address[] memory) {
    return _airdrops(_domani);
  }

  /**
   * Get boolean indicating if token is approved for airdrops.
   *
   * @param _domani             Address of Domani
   * @return                      Boolean indicating approval for airdrops
   */
  function isAirdropToken(IDomani _domani, address _token) public view returns (bool) {
    return _airdrops(_domani).contains(_token);
  }

  /* ============ Internal Functions ============ */

  /**
   * Check token approved for airdrops then handle airdropped postion.
   */
  function _absorb(IDomani _domani, address _token) internal {
    require(isAirdropToken(_domani, _token), "Must be approved token.");

    _handleAirdropPosition(_domani, _token);
  }

  function _batchAbsorb(IDomani _domani, address[] memory _tokens) internal {
    for (uint256 i = 0; i < _tokens.length; i++) {
      _absorb(_domani, _tokens[i]);
    }
  }

  /**
   * Calculate amount of tokens airdropped since last absorption, then distribute fees and update position.
   *
   * @param _domani                 Address of Domani
   * @param _token                    Address of airdropped token
   */
  function _handleAirdropPosition(IDomani _domani, address _token) internal {
    uint256 preFeeTokenBalance = ERC20(_token).balanceOf(address(_domani));
    uint256 amountAirdropped = preFeeTokenBalance.sub(_domani.getDefaultTrackedBalance(_token));

    if (amountAirdropped > 0) {
      (uint256 managerTake, uint256 protocolTake, uint256 totalFees) = _handleFees(
        _domani,
        _token,
        amountAirdropped
      );

      uint256 newUnit = _getPostAirdropUnit(_domani, preFeeTokenBalance, totalFees);

      _domani.editDefaultPosition(_token, newUnit);

      emit ComponentAbsorbed(_domani, _token, amountAirdropped, managerTake, protocolTake);
    }
  }

  /**
   * Calculate fee total and distribute between feeRecipient defined on module and the protocol feeRecipient.
   *
   * @param _domani                 Address of Domani
   * @param _component                Address of airdropped component
   * @param _amountAirdropped         Amount of tokens airdropped to the Domani
   * @return                          Amount of airdropped tokens set aside for manager fees
   * @return                          Amount of airdropped tokens set aside for protocol fees
   * @return                          Total fees paid
   */
  function _handleFees(
    IDomani _domani,
    address _component,
    uint256 _amountAirdropped
  )
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 airdropFee = airdropSettings[_domani].airdropFee;

    if (airdropFee > 0) {
      uint256 managerTake = _amountAirdropped.preciseMul(airdropFee);

      uint256 protocolTake = ModuleBase.getModuleFee(
        AIRDROP_MODULE_PROTOCOL_FEE_INDEX,
        managerTake
      );
      uint256 netManagerTake = managerTake.sub(protocolTake);
      uint256 totalFees = netManagerTake.add(protocolTake);

      _domani.invokeTransfer(_component, airdropSettings[_domani].feeRecipient, netManagerTake);

      ModuleBase.payProtocolFeeFromDomani(_domani, _component, protocolTake);

      return (netManagerTake, protocolTake, totalFees);
    } else {
      return (0, 0, 0);
    }
  }

  /**
   * Retrieve new unit, which is the current balance less fees paid divided by total supply
   */
  function _getPostAirdropUnit(
    IDomani _domani,
    uint256 _totalComponentBalance,
    uint256 _totalFeesPaid
  ) internal view returns (uint256) {
    uint256 totalSupply = _domani.totalSupply();
    return totalSupply.getDefaultPositionUnit(_totalComponentBalance.sub(_totalFeesPaid));
  }

  /**
   * If absorption is confined to the manager, manager must be caller
   */
  function _isValidCaller(IDomani _domani) internal view returns (bool) {
    return airdropSettings[_domani].anyoneAbsorb || isDomaniManager(_domani, msg.sender);
  }

  function _airdrops(IDomani _domani) internal view returns (address[] memory) {
    return airdropSettings[_domani].airdrops;
  }
}