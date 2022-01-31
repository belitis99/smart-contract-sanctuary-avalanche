/**
 *Submitted for verification at snowtrace.io on 2021-12-08
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/GSN/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;



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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/math/[email protected]

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


// File contracts/lib/AddressArrayUtils.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Cook Finance
 *
 * Utility functions to handle Address Arrays
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
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
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
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
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
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
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


// File contracts/interfaces/IController.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface IController {
    function addCK(address _ckToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isCK(address _ckToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}


// File contracts/interfaces/ICKToken.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

/**
 * @title ICKToken
 * @author Cook Finance
 *
 * Interface for operating with CKTokens.
 */
interface ICKToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a CKToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a CKToken
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
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

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
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}


// File contracts/interfaces/IManagerIssuanceHook.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface IManagerIssuanceHook {
    function invokePreIssueHook(ICKToken _ckToken, uint256 _issueQuantity, address _sender, address _to) external;
    function invokePreRedeemHook(ICKToken _ckToken, uint256 _redeemQuantity, address _sender, address _to) external;
}


// File contracts/interfaces/IModuleIssuanceHook.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

/**
 * CHANGELOG:
 *      - Added a module level issue hook that can be used to set state ahead of component level
 *        issue hooks
 */
interface IModuleIssuanceHook {

    function moduleIssueHook(ICKToken _ckToken, uint256 _ckTokenQuantity) external;
    function moduleRedeemHook(ICKToken _ckToken, uint256 _ckTokenQuantity) external;
    
    function componentIssueHook(
        ICKToken _ckToken,
        uint256 _ckTokenQuantity,
        IERC20 _component,
        bool _isEquity
    ) external;

    function componentRedeemHook(
        ICKToken _ckToken,
        uint256 _ckTokenQuantity,
        IERC20 _component,
        bool _isEquity
    ) external;
}


// File contracts/protocol/lib/Invoke.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;


/**
 * @title Invoke
 * @author Cook Finance
 *
 * A collection of common utility functions for interacting with the CKToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the CKToken to set approvals of the ERC20 token to a spender.
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the CKToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        ICKToken _ckToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _ckToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the CKToken to transfer the ERC20 token to a recipient.
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        ICKToken _ckToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _ckToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the CKToken to transfer the ERC20 token to a recipient.
     * The new CKToken balance must equal the existing balance less the quantity transferred
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        ICKToken _ckToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the CKToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_ckToken));

            Invoke.invokeTransfer(_ckToken, _token, _to, _quantity);

            // Get new balance of transferred token for CKToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_ckToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the CKToken to unwrap the passed quantity of WETH
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(ICKToken _ckToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _ckToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the CKToken to wrap the passed quantity of ETH
     *
     * @param _ckToken        CKToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(ICKToken _ckToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _ckToken.invoke(_weth, _quantity, callData);
    }
}


// File contracts/interfaces/external/IWETH.sol

/*
    Copyright 2018 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;

/**
 * @title IWETH
 * @author Cook Finance
 *
 * Interface for Wrapped Ether. This interface allows for interaction for wrapped ether's deposit and withdrawal
 * functionality.
 */
interface IWETH is IERC20{
    function deposit()
        external
        payable;

    function withdraw(
        uint256 wad
    )
        external;
}


// File contracts/interfaces/IWrapAdapter.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;


/**
 * @title IWrapAdapter
 * @author Cook Finance
 *
 */
interface IWrapAdapter {

    function ETH_TOKEN_ADDRESS() external view returns (address);

    function getWrapCallData(
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingUnits
    ) external view returns (address _subject, uint256 _value, bytes memory _calldata);

    function getUnwrapCallData(
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedTokenUnits
    ) external view returns (address _subject, uint256 _value, bytes memory _calldata);

    function getSpenderAddress(address _underlyingToken, address _wrappedToken) external view returns(address);

    function getWrapSpenderAddress(address _underlyingToken, address _wrappedToken) external view returns(address);

    function getUnwrapSpenderAddress(address _underlyingToken, address _wrappedToken) external view returns(address);

    function getDepositUnderlyingTokenAmount(address _underlyingToken, address _wrappedToken, uint256 _wrappedTokenAmount) external view returns(uint256);

    function getWithdrawUnderlyingTokenAmount(address _underlyingToken, address _wrappedToken, uint256 _wrappedTokenAmount) external view returns(uint256);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;



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


// File contracts/lib/ExplicitERC20.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;



/**
 * @title ExplicitERC20
 * @author Cook Finance
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
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
    }
}


// File contracts/interfaces/IModule.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;


/**
 * @title IModule
 * @author Cook Finance
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a CKToken to notify that this module was removed from the CK token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}


// File contracts/lib/PreciseUnitMath.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;


/**
 * @title PreciseUnitMath
 * @author Cook Finance
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

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
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }
}


// File contracts/protocol/lib/Position.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;





/**
 * @title Position
 * @author Cook Finance
 *
 * Collection of helper functions for handling and updating CKToken Positions
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
     * Returns whether the CKToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(ICKToken _ckToken, address _component) internal view returns(bool) {
        return _ckToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the CKToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(ICKToken _ckToken, address _component) internal view returns(bool) {
        return _ckToken.getExternalPositionModules(_component).length > 0;
    }
    
    /**
     * Returns whether the CKToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(ICKToken _ckToken, address _component, uint256 _unit) internal view returns(bool) {
        return _ckToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }

    /**
     * Returns whether the CKToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        ICKToken _ckToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _ckToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();    
    }

    /**
     * If the position does not exist, create a new Position and add to the CKToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of 
     * components where needed (in light of potential external positions).
     *
     * @param _ckToken           Address of CKToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(ICKToken _ckToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_ckToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_ckToken, _component)) {
                _ckToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_ckToken, _component)) {
                _ckToken.removeComponent(_component);
            }
        }

        _ckToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
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
     * @param _ckToken         CKToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        ICKToken _ckToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (_newUnit != 0) {
            if (!_ckToken.isComponent(_component)) {
                _ckToken.addComponent(_component);
                _ckToken.addExternalPositionModule(_component, _module);
            } else if (!_ckToken.isExternalPositionModule(_component, _module)) {
                _ckToken.addExternalPositionModule(_component, _module);
            }
            _ckToken.editExternalPositionUnit(_component, _module, _newUnit);
            _ckToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (_ckToken.getExternalPositionRealUnit(_component, _module) != 0) {
                address[] memory positionModules = _ckToken.getExternalPositionModules(_component);
                if (_ckToken.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == _module, "External positions must be 0 to remove component");
                    _ckToken.removeComponent(_component);
                }
                _ckToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _ckTokenSupply     Supply of CKToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 _ckTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _ckTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _ckTokenSupply     Supply of CKToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(uint256 _ckTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_ckTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _ckToken           Address of the CKToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(ICKToken _ckToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _ckToken.getDefaultPositionRealUnit(_component); 
        return _ckToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _ckToken                 Address of the CKToken
     * @param _component                Address of the component
     * @param _ckTotalSupply           Current CKToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        ICKToken _ckToken,
        address _component,
        uint256 _ckTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_ckToken));
        uint256 positionUnit = _ckToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _ckTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_ckToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes CKToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _ckTokenSupply     Supply of CKToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of CKToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _ckTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_ckTokenSupply));
        return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_ckTokenSupply);
    }
}


// File contracts/interfaces/IIntegrationRegistry.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}


// File contracts/interfaces/IPriceOracle.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

/**
 * @title IPriceOracle
 * @author Cook Finance
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}


// File contracts/interfaces/ICKValuer.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface ICKValuer {
    function calculateCKTokenValuation(ICKToken _ckToken, address _quoteAsset) external view returns (uint256);
}


// File contracts/protocol/lib/ResourceIdentifier.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;




/**
 * @title ResourceIdentifier
 * @author Cook Finance
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // CKValuer resource will always be resource ID 2 in the system
    uint256 constant internal CK_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of CK valuer on Controller. Note: CKValuer is stored as index 2 on the Controller
     */
    function getCKValuer(IController _controller) internal view returns (ICKValuer) {
        return ICKValuer(_controller.resourceId(CK_VALUER_RESOURCE_ID));
    }
}


// File contracts/protocol/lib/ModuleBase.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.6.10;












/**
 * @title ModuleBase
 * @author Cook Finance
 *
 * Abstract class that houses common Module-related state and functions.
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for ICKToken;
    using Position for ICKToken;
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

    modifier onlyManagerAndValidCK(ICKToken _ckToken) { 
        _validateOnlyManagerAndValidCK(_ckToken);
        _;
    }

    modifier onlyCKManager(ICKToken _ckToken, address _caller) {
        _validateOnlyCKManager(_ckToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedCK(ICKToken _ckToken) {
        _validateOnlyValidAndInitializedCK(_ckToken);
        _;
    }

    /**
     * Throws if the sender is not a CKToken's module or module not enabled
     */
    modifier onlyModule(ICKToken _ckToken) {
        _validateOnlyModule(_ckToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the CKToken is valid
     */
    modifier onlyValidAndPendingCK(ICKToken _ckToken) {
        _validateOnlyValidAndPendingCK(_ckToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) { 
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) { 
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
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _ckToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromCKToken(ICKToken _ckToken, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _ckToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity); 
        }
    }

    /**
     * Returns true if the module is in process of initialization on the CKToken
     */
    function isCKPendingInitialization(ICKToken _ckToken) internal view returns(bool) {
        return _ckToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the CKToken's manager
     */
    function isCKManager(ICKToken _ckToken, address _toCheck) internal view returns(bool) {
        return _ckToken.manager() == _toCheck;
    }

    /**
     * Returns true if CKToken must be enabled on the controller 
     * and module is registered on the CKToken
     */
    function isCKValidAndInitialized(ICKToken _ckToken) internal view returns(bool) {
        return controller.isCK(address(_ckToken)) &&
            _ckToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must CKToken manager and CKToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidCK(ICKToken _ckToken) internal view {
       require(isCKManager(_ckToken, msg.sender), "Must be the CKToken manager");
       require(isCKValidAndInitialized(_ckToken), "Must be a valid and initialized CKToken");
    }

    /**
     * Caller must CKToken manager
     */
    function _validateOnlyCKManager(ICKToken _ckToken, address _caller) internal view {
        require(isCKManager(_ckToken, _caller), "Must be the CKToken manager");
    }

    /**
     * CKToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedCK(ICKToken _ckToken) internal view {
        require(isCKValidAndInitialized(_ckToken), "Must be a valid and initialized CKToken");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(ICKToken _ckToken) internal view {
        require(
            _ckToken.moduleStates(msg.sender) == ICKToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * CKToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingCK(ICKToken _ckToken) internal view {
        require(controller.isCK(address(_ckToken)), "Must be controller-enabled CKToken");
        require(isCKPendingInitialization(_ckToken), "Must be pending initialization");
    }
}


// File contracts/interfaces/IExchangeAdapter.sol

/*
    Copyright 2021 Cook Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/
pragma solidity 0.6.10;

interface IExchangeAdapter {
    function getSpender() external view returns(address);
    function getTradeCalldata(
        address _fromToken,
        address _toToken,
        address _toAddress,
        uint256 _fromQuantity,
        uint256 _minToQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory);
    function getMinAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function getMaxAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
    function generateDataParam(address[] memory path, bool _isSendTokenFixed) external pure returns (bytes memory);
}


// File contracts/interfaces/external/IYieldYakStrategyV2.sol

pragma solidity 0.6.10;


/**
 * @title Yield Yak Strategy2 Interface
 */
interface IYieldYakStrategyV2 {

    // function depositToken() external view returns (IERC20);
    // function rewardToken() external view returns (address);
    // function devAddr() external view returns (address);

    // function MIN_TOKENS_TO_REINVEST() external view returns (uint);
    // function MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST() external view returns (uint);
    // function DEPOSITS_ENABLED() external view returns (bool);

    // function REINVEST_REWARD_BIPS() external view returns (uint);
    // function ADMIN_FEE_BIPS() external view returns (uint);
    // function DEV_FEE_BIPS() external view returns (uint);

    // function BIPS_DIVISOR() external view returns (uint);
    // function MAX_UINT() external view returns (uint);

    function deposit(uint amount) external;
    function withdraw(uint amount) external; 
    function getSharesForDepositTokens(uint amount) external view returns (uint);
    function getDepositTokensForShares(uint amount) external view returns (uint);
}


// File contracts/protocol/modules/IssuanceModule.sol

/*
    Copyright 2021 Cook Finance.

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

pragma solidity 0.6.10;




















/**
 * @title IssuanceModule
 * @author Cook Finance
 *
 * The IssuanceModule is a module that enables users to issue and redeem CKTokens that contain default and 
 * non-debt external Positions. Managers are able to set an external contract hook that is called before an
 * issuance is called.
 */
contract IssuanceModule is Ownable, ModuleBase, ReentrancyGuard {
    using AddressArrayUtils for address[];
    using Invoke for ICKToken;
    using Position for ICKToken;
    using Position for uint256;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;

    /* ============ Struct ============ */
    struct WrapExecutionParams {
        string wrapAdapterName;     // Wrap adapter name
        address underlyingToken;    // Underlying token address of the wrapped token, ex. WETH is the underlying token of the aETH. This will be passed to wrap adapter to get wrap/unwrap call data
    }

    struct TradeInfo {
        ICKToken ckToken;                               // Instance of CKToken
        IExchangeAdapter exchangeAdapter;               // Instance of exchange adapter contract
        address sendToken;                              // Address of token being sold
        address receiveToken;                           // Address of token being bought
        uint256 totalSendQuantity;                      // Total quantity of sold token
        uint256 totalReceiveQuantity;                   // Total quantity of token to receive back
        uint256 preTradeSendTokenBalance;               // Total initial balance of token being sold
        uint256 preTradeReceiveTokenBalance;            // Total initial balance of token being bought
        bytes data;                                     // Arbitrary data
    }

    /* ============ Events ============ */

    event CKTokenIssued(address indexed _ckToken, address _issuer, address _to, address _hookContract, uint256 _ckMintQuantity, uint256 _issuedTokenReturned);
    event CKTokenRedeemed(address indexed _ckToken, address _redeemer, address _to, uint256 _quantity);
    event AssetExchangeExecutionParamUpdated(address indexed _component, string _newExchangeName);
    event AssetWrapExecutionParamUpdated(address indexed _component, string _newWrapAdapterName, address _newUnderlyingToken);
    event ComponentExchanged(
        ICKToken indexed _ckToken,
        address indexed _sendToken,
        address indexed _receiveToken,
        IExchangeAdapter _exchangeAdapter,
        uint256 _totalSendAmount,
        uint256 _totalReceiveAmount
    );
    event ComponentWrapped(
        ICKToken indexed _ckToken,
        address indexed _underlyingToken,
        address indexed _wrappedToken,
        uint256 _underlyingQuantity,
        uint256 _wrappedQuantity,
        string _integrationName
    );
    event ComponentUnwrapped(
        ICKToken indexed _ckToken,
        address indexed _underlyingToken,
        address indexed _wrappedToken,
        uint256 _underlyingQuantity,
        uint256 _wrappedQuantity,
        string _integrationName
    );

    /* ============ State Variables ============ */

    // Mapping of CKToken to Issuance hook configurations
    mapping(ICKToken => IManagerIssuanceHook) public managerIssuanceHook;
    // Mapping of asset to exchange execution parameters
    mapping(IERC20 => string) public exchangeInfo;
    // Mapping of asset to wrap execution parameters
    mapping(IERC20 => WrapExecutionParams) public wrapInfo;
    // Wrapped ETH address
    IWETH public immutable weth;

    /* ============ Constructor ============ */

    /**
     * Set state controller state variable
     */
    constructor(IController _controller, IWETH _weth) public ModuleBase(_controller) {
        weth = _weth;
    }

    /* ============ External Functions ============ */

    /**
     * Issue ckToken with a specified amount of a single token.
     *
     * @param _ckToken              Instance of the CKToken contract
     * @param _issueToken           Address of the issue token
     * @param _issueTokenQuantity   Quantity of the issue token
     * @param _slippage             Percentage of single token reserved to handle slippage
     * @param _to                   Address to mint CKToken to
     * @param _returnDust           If to return left component
     */
    function issueWithSingleToken(
        ICKToken _ckToken,
        address _issueToken,
        uint256 _issueTokenQuantity,
        uint256 _slippage,
        address _to,
        bool _returnDust
    )
        external
        nonReentrant
        onlyValidAndInitializedCK(_ckToken)
    {
        require(_issueTokenQuantity > 0, "Issue token quantity must be > 0");
        // Transfer the specified issue token to ckToken
        transferFrom(
            IERC20(_issueToken),
            msg.sender,
            address(_ckToken),
            _issueTokenQuantity
        );

        uint256 issueTokenRemain = _issueWithSingleToken(_ckToken, _issueToken, _issueTokenQuantity, _slippage, _to, _returnDust);

        // transfer the remaining issue token to issuer
        _ckToken.strictInvokeTransfer(
            _issueToken,
            msg.sender,
            issueTokenRemain
        );
    }

    /**
     * Issue ckToken with a specified amount of ETH.
     *
     * @param _ckToken              Instance of the CKToken amount
     * @param _slippage             Percentage of single token reserved to handle slippage
     * @param _to                   Address to mint CKToken to
     * @param _returnDust           If to return left component
     */
    function issueWithEther(
        ICKToken _ckToken,
        uint256 _slippage,
        address _to,
        bool _returnDust
    )
        external
        payable
        nonReentrant
        onlyValidAndInitializedCK(_ckToken)
    {
        require(msg.value > 0, "Issue ether quantity must be > 0");
        weth.deposit{ value: msg.value }();
        // Transfer the specified weth to ckToken
        transferFrom(
            weth,
            address(this),
            address(_ckToken),
            msg.value
        );
        uint256 issueTokenRemain = _issueWithSingleToken(_ckToken, address(weth), msg.value, _slippage, _to, _returnDust);
        // transfer the remaining weth to issuer
        _ckToken.strictInvokeTransfer(
            address(weth),
            msg.sender,
            issueTokenRemain
        );
    }

    /**
     * Issue ckToken with a specified amount of Eth. 
     *
     * @param _ckToken              Instance of the CKToken contract
     * @param _minCkTokenRec        The minimum amount of CKToken to receive
     * @param _weightings           Eth distribution for each component
     * @param _to                   Address to mint CKToken to
     * @param _returnDust           If to return left components
     */
    function issueWithEther2(
        ICKToken _ckToken,
        uint256 _minCkTokenRec,
        uint256[] memory _weightings,
        address _to,
        bool _returnDust
    )         
        external
        payable
        nonReentrant
        onlyValidAndInitializedCK(_ckToken) 
    {
        require(msg.value > 0, "Issue ether quantity must be > 0");
        weth.deposit{ value: msg.value }();
        // Transfer the specified weth to ckToken
        transferFrom(
            weth,
            address(this),
            address(_ckToken),
            msg.value
        );
        uint256 issueTokenRemain = _issueWithSingleToken2(_ckToken, address(weth), msg.value, _minCkTokenRec, _weightings, _to, _returnDust);
        // transfer the remaining weth to issuer
        _ckToken.strictInvokeTransfer(
            address(weth),
            msg.sender,
            issueTokenRemain
        );
    }

    /**
     * Issue ckToken with a specified amount of a single asset with specification
     *
     * @param _ckToken              Instance of the CKToken contract
     * @param _issueToken           token used to issue with
     * @param _issueTokenQuantity   amount of issue tokens
     * @param _minCkTokenRec        The minimum amount of CKToken to receive
     * @param _weightings           Eth distribution for each component
     * @param _to                   Address to mint CKToken to
     * @param _returnDust           If to return left components
     */
    function issueWithSingleToken2 (
        ICKToken _ckToken,
        address _issueToken,
        uint256 _issueTokenQuantity,
        uint256 _minCkTokenRec,
        uint256[] memory _weightings,  // percentage in 18 decimals and order should follow ckComponents get from a ck token
        address _to,
        bool _returnDust
    )   
        external
        nonReentrant
        onlyValidAndInitializedCK(_ckToken) 
    {
        require(_issueTokenQuantity > 0, "Issue token quantity must be > 0");
        // Transfer the specified issue token to ckToken
        transferFrom(
            IERC20(_issueToken),
            msg.sender,
            address(_ckToken),
            _issueTokenQuantity
        );        
        
        uint256 issueTokenRemain = _issueWithSingleToken2(_ckToken, _issueToken, _issueTokenQuantity, _minCkTokenRec, _weightings, _to, _returnDust);
        // transfer the remaining weth to issuer
        _ckToken.strictInvokeTransfer(
            address(_issueToken),
            msg.sender,
            issueTokenRemain
        );
        
    }

    /**
     * Burns a user's CKToken of specified quantity, unwinds external positions, and exchange components
     * to the specified token and return to the specified address. Does not work for debt/negative external positions.
     *
     * @param _ckToken             Instance of the CKToken contract
     * @param _ckTokenQuantity     Quantity of the CKToken to redeem
     * @param _redeemToken         Address of redeem token
     * @param _to                  Address to redeem CKToken to
     * @param _minRedeemTokenToRec Minimum redeem to to receive
     */
    function redeemToSingleToken(
        ICKToken _ckToken,
        uint256 _ckTokenQuantity,
        address _redeemToken,
        address _to,
        uint256 _minRedeemTokenToRec
    )
        external
        nonReentrant
        onlyValidAndInitializedCK(_ckToken)
    {
        require(_ckTokenQuantity > 0, "Redeem quantity must be > 0");
        _ckToken.burn(msg.sender, _ckTokenQuantity);

        (
            address[] memory components,
            uint256[] memory componentQuantities
        ) = getRequiredComponentIssuanceUnits(_ckToken, _ckTokenQuantity, false);
        uint256 totalRedeemTokenAcquired = 0;
        for (uint256 i = 0; i < components.length; i++) {
            _executeExternalPositionHooks(_ckToken, _ckTokenQuantity, IERC20(components[i]), false);
            uint256 redeemTokenAcquired = _exchangeDefaultPositionsToRedeemToken(_ckToken, _redeemToken, components[i], componentQuantities[i]);
            totalRedeemTokenAcquired = totalRedeemTokenAcquired.add(redeemTokenAcquired);
        }

        require(totalRedeemTokenAcquired >= _minRedeemTokenToRec, "_minRedeemTokenToRec not met");

        _ckToken.strictInvokeTransfer(
            _redeemToken,
            _to,
            totalRedeemTokenAcquired
        );

        emit CKTokenRedeemed(address(_ckToken), msg.sender, _to, _ckTokenQuantity);
    }

    /**
     * Initializes this module to the CKToken with issuance-related hooks. Only callable by the CKToken's manager.
     * Hook addresses are optional. Address(0) means that no hook will be called
     *
     * @param _ckToken             Instance of the CKToken to issue
     * @param _preIssueHook         Instance of the Manager Contract with the Pre-Issuance Hook function
     */
    function initialize(
        ICKToken _ckToken,
        IManagerIssuanceHook _preIssueHook
    )
        external
        onlyCKManager(_ckToken, msg.sender)
        onlyValidAndPendingCK(_ckToken)
    {
        managerIssuanceHook[_ckToken] = _preIssueHook;

        _ckToken.initializeModule();
    }

    /**
     * Removes this module from the CKToken, via call by the CKToken. Left with empty logic
     * here because there are no check needed to verify removal.
     */
    function removeModule() external override {}

    /**
     * OWNER ONLY: Set exchange for passed components of the CKToken. Can be called at anytime.
     *
     * @param _components           Array of components
     * @param _exchangeNames        Array of exchange names mapping to correct component
     */
    function setExchanges(
        address[] memory _components,
        string[] memory _exchangeNames
    )
        external
        onlyOwner
    {
        _components.validatePairsWithArray(_exchangeNames);

        for (uint256 i = 0; i < _components.length; i++) {
            require(
                controller.getIntegrationRegistry().isValidIntegration(address(this), _exchangeNames[i]),
                "Unrecognized exchange name"
            );

            exchangeInfo[IERC20(_components[i])] = _exchangeNames[i];
            emit AssetExchangeExecutionParamUpdated(_components[i], _exchangeNames[i]);
        }
    }

    /**
     * OWNER ONLY: Set wrap adapters for passed components of the CKToken. Can be called at anytime.
     *
     * @param _components           Array of components
     * @param _wrapAdapterNames     Array of wrap adapter names mapping to correct component
     * @param _underlyingTokens     Array of underlying tokens mapping to correct component
     */
    function setWrapAdapters(
        address[] memory _components,
        string[] memory _wrapAdapterNames,
        address[] memory _underlyingTokens
    )
    external
    onlyOwner
    {
        _components.validatePairsWithArray(_wrapAdapterNames);
        _components.validatePairsWithArray(_underlyingTokens);

        for (uint256 i = 0; i < _components.length; i++) {
            require(
                controller.getIntegrationRegistry().isValidIntegration(address(this), _wrapAdapterNames[i]),
                "Unrecognized wrap adapter name"
            );

            wrapInfo[IERC20(_components[i])].wrapAdapterName = _wrapAdapterNames[i];
            wrapInfo[IERC20(_components[i])].underlyingToken = _underlyingTokens[i];
            emit AssetWrapExecutionParamUpdated(_components[i], _wrapAdapterNames[i], _underlyingTokens[i]);
        }
    }

    /**
     * Retrieves the addresses and units required to issue/redeem a particular quantity of CKToken.
     *
     * @param _ckToken             Instance of the CKToken to issue
     * @param _quantity             Quantity of CKToken to issue
     * @param _isIssue              Boolean whether the quantity is issuance or redemption
     * @return address[]            List of component addresses
     * @return uint256[]            List of component units required for a given CKToken quantity
     */
    function getRequiredComponentIssuanceUnits(
        ICKToken _ckToken,
        uint256 _quantity,
        bool _isIssue
    )
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        (
            address[] memory components,
            uint256[] memory issuanceUnits
        ) = _getTotalIssuanceUnits(_ckToken);

        uint256[] memory notionalUnits = new uint256[](components.length);
        for (uint256 i = 0; i < issuanceUnits.length; i++) {
            // Use preciseMulCeil to round up to ensure overcollateration when small issue quantities are provided
            // and preciseMul to round down to ensure overcollateration when small redeem quantities are provided
            notionalUnits[i] = _isIssue ? 
                issuanceUnits[i].preciseMulCeil(_quantity) : 
                issuanceUnits[i].preciseMul(_quantity);
            require(notionalUnits[i] > 0, "component amount should not be zero");
        }

        return (components, notionalUnits);
    }

    /* ============ Internal Functions ============ */

    /**
     * Issue ckToken with a specified amount of a single token.
     *
     * @param _ckToken              Instance of the CKToken contract
     * @param _issueToken           Address of the issue token
     * @param _issueTokenQuantity   Quantity of the issue token
     * @param _slippage             Percentage of single token reserved to handle slippage
     * @param _to                   Address to mint CKToken to
     */
    function _issueWithSingleToken(
        ICKToken _ckToken,
        address _issueToken,
        uint256 _issueTokenQuantity,
        uint256 _slippage,
        address _to,
        bool _returnDust
    )
        internal
        returns(uint256)
    {
        // Calculate how many ckTokens can be issued with the specified amount of issue token
        // Get valuation of the CKToken with the quote asset as the issue token. Returns value in precise units (1e18)
        // Reverts if price is not found
        uint256 ckTokenValuation = controller.getCKValuer().calculateCKTokenValuation(_ckToken, _issueToken);
        uint256 ckTokenQuantity = _issueTokenQuantity.preciseDiv(uint256(10).safePower(uint256(ERC20(_issueToken).decimals()))).preciseMul(PreciseUnitMath.preciseUnit().sub(_slippage)).preciseDiv(ckTokenValuation);
        address hookContract = _callPreIssueHooks(_ckToken, ckTokenQuantity, msg.sender, _to);
        // Get components and required notional amount to issue ckTokens    
        (uint256 ckTokenQuantityToMint, uint256 issueTokenRemain)= _tradeAndWrapComponents(_ckToken, _issueToken, _issueTokenQuantity, ckTokenQuantity, _returnDust);
        _ckToken.mint(_to, ckTokenQuantityToMint);

        emit CKTokenIssued(address(_ckToken), msg.sender, _to, hookContract, ckTokenQuantityToMint, issueTokenRemain);
        return issueTokenRemain;
    }

    /**
     * This is a internal implementation for issue ckToken with a specified amount of a single asset with specification. 
     *
     * @param _ckToken              Instance of the CKToken contract
     * @param _issueToken           token used to issue with
     * @param _issueTokenQuantity   amount of issue tokens
     * @param _minCkTokenRec        The minimum amount of CKToken to receive
     * @param _weightings           Eth distribution for each component
     * @param _to                   Address to mint CKToken to
     * @param _returnDust           If to return left components
     */
    function _issueWithSingleToken2(   
        ICKToken _ckToken,
        address _issueToken,
        uint256 _issueTokenQuantity,
        uint256 _minCkTokenRec,
        uint256[] memory _weightings,
        address _to,
        bool _returnDust
    ) 
        internal 
        returns(uint256)
    {
        address hookContract = _callPreIssueHooks(_ckToken, _minCkTokenRec, msg.sender, _to);
        address[] memory components = _ckToken.getComponents();
        require(components.length == _weightings.length, "weightings mismatch");
        (uint256 maxCkTokenToIssue, uint256 returnedIssueToken) = _issueWithSpec(_ckToken, _issueToken, _issueTokenQuantity, components, _weightings, _returnDust);
        require(maxCkTokenToIssue >= _minCkTokenRec, "_minCkTokenRec not met");

        _ckToken.mint(_to, maxCkTokenToIssue);

        emit CKTokenIssued(address(_ckToken), msg.sender, _to, hookContract, maxCkTokenToIssue, returnedIssueToken);        
        
        return returnedIssueToken;
    }

    function _issueWithSpec(ICKToken _ckToken, address _issueToken, uint256 _issueTokenQuantity, address[] memory components, uint256[] memory _weightings, bool _returnDust) 
        internal 
        returns(uint256, uint256)
    {
        uint256 maxCkTokenToIssue = PreciseUnitMath.MAX_UINT_256;
        uint256[] memory componentTokenReceiveds = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            uint256 _issueTokenAmountToUse = _issueTokenQuantity.preciseMul(_weightings[i]).sub(1); // avoid underflow
            uint256 componentRealUnitRequired = (_ckToken.getDefaultPositionRealUnit(components[i])).toUint256();
            uint256 componentReceived = _tradeAndWrapComponents2(_ckToken, _issueToken, _issueTokenAmountToUse, components[i]);
            componentTokenReceiveds[i] = componentReceived;
            // guarantee issue ck token amount.
            uint256 maxIssue = componentReceived.preciseDiv(componentRealUnitRequired);
            if (maxIssue <= maxCkTokenToIssue) {
                maxCkTokenToIssue = maxIssue;
            }
        }   

        uint256 issueTokenToReturn = _dustToReturn(_ckToken, _issueToken, componentTokenReceiveds, maxCkTokenToIssue, _returnDust);
 
        return (maxCkTokenToIssue, issueTokenToReturn);
    }

    function _tradeAndWrapComponents2(ICKToken _ckToken, address _issueToken, uint256 _issueTokenAmountToUse, address _component) internal returns(uint256) {
        uint256 componentTokenReceived;
        if (_issueToken == _component) {
            componentTokenReceived = _issueTokenAmountToUse;     
        } else if (wrapInfo[IERC20(_component)].underlyingToken == address(0)) {
            // For underlying tokens, exchange directly
            (, componentTokenReceived) = _trade(_ckToken, _issueToken, _component, _issueTokenAmountToUse, true);
        } else {
            // For wrapped tokens, exchange to underlying tokens first and then wrap it
            WrapExecutionParams memory wrapExecutionParams = wrapInfo[IERC20(_component)];
            IWrapAdapter wrapAdapter = IWrapAdapter(getAndValidateAdapter(wrapExecutionParams.wrapAdapterName));
            uint256 underlyingReceived = 0;
            if (wrapExecutionParams.underlyingToken == wrapAdapter.ETH_TOKEN_ADDRESS()) {
                if (_issueToken != address(weth)) {
                    (, underlyingReceived) = _trade(_ckToken, _issueToken, address(weth), _issueTokenAmountToUse, true);
                } else {
                    underlyingReceived = _issueTokenAmountToUse;
                }
                componentTokenReceived = _wrap(_ckToken, wrapExecutionParams.underlyingToken, _component, underlyingReceived, wrapExecutionParams.wrapAdapterName, true);
            } else {
                (, underlyingReceived) = _trade(_ckToken, _issueToken, wrapExecutionParams.underlyingToken, _issueTokenAmountToUse, true);
                componentTokenReceived = _wrap(_ckToken, wrapExecutionParams.underlyingToken, _component, underlyingReceived, wrapExecutionParams.wrapAdapterName, false);
            }
        }

        return componentTokenReceived;
    }
    

    function _tradeAndWrapComponents(ICKToken _ckToken, address _issueToken, uint256 issueTokenRemain, uint256 ckTokenQuantity, bool _returnDust)
        internal
        returns(uint256, uint256)
    {
        (
        address[] memory components,
        uint256[] memory componentQuantities
        ) = getRequiredComponentIssuanceUnits(_ckToken, ckTokenQuantity, true);
        // Transform the issue token to each components
        uint256 issueTokenSpent;
        uint256 componentTokenReceived;
        uint256 minIssuePercentage = 10 ** 18;
        uint256[] memory componentTokenReceiveds = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            (issueTokenSpent, componentTokenReceived) = _exchangeIssueTokenToDefaultPositions(_ckToken, _issueToken, components[i], componentQuantities[i]);
            require(issueTokenRemain >= issueTokenSpent, "Not enough issue token remaining");
            issueTokenRemain = issueTokenRemain.sub(issueTokenSpent);
            _executeExternalPositionHooks(_ckToken, ckTokenQuantity, IERC20(components[i]), true);

            // guarantee issue ck token amount.
            uint256 issuePercentage = componentTokenReceived.preciseDiv(componentQuantities[i]);
            if (issuePercentage <= minIssuePercentage) {
                minIssuePercentage = issuePercentage;
            }
            componentTokenReceiveds[i] = componentTokenReceived;
        }

        uint256 maxCkTokenToIssue = ckTokenQuantity.preciseMul(minIssuePercentage);
        issueTokenRemain = issueTokenRemain.add(_dustToReturn(_ckToken, _issueToken, componentTokenReceiveds, maxCkTokenToIssue, _returnDust));

        return (maxCkTokenToIssue, issueTokenRemain);
    }

    /**
     * Swap remaining component back to issue token.
     */
    function _dustToReturn(ICKToken _ckToken, address _issueToken, uint256[] memory componentTokenReceiveds, uint256 maxCkTokenToIssue, bool _returnDust) internal returns(uint256) {
        if (!_returnDust) {
            return 0;
        }
        uint256 issueTokenToReturn = 0;
        address[] memory components = _ckToken.getComponents();

        for(uint256 i = 0; i < components.length; i++) {
            uint256 requiredComponentUnit = ((_ckToken.getDefaultPositionRealUnit(components[i])).toUint256()).preciseMul(maxCkTokenToIssue);
            uint256 toReturn = componentTokenReceiveds[i].sub(requiredComponentUnit);
            uint256 diffPercentage = toReturn.preciseDiv(requiredComponentUnit); // percentage in 18 decimals
            if (diffPercentage > (PreciseUnitMath.preciseUnit().div(10000))) { // 0.01%
                issueTokenToReturn = issueTokenToReturn.add(_exchangeDefaultPositionsToRedeemToken(_ckToken, _issueToken, components[i], toReturn));
            }
        }     

        return issueTokenToReturn;
    }    

    /**
     * Retrieves the component addresses and list of total units for components. This will revert if the external unit
     * is ever equal or less than 0 .
     */
    function _getTotalIssuanceUnits(ICKToken _ckToken) internal view returns (address[] memory, uint256[] memory) {
        address[] memory components = _ckToken.getComponents();
        uint256[] memory totalUnits = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            int256 cumulativeUnits = _ckToken.getDefaultPositionRealUnit(component);

            address[] memory externalModules = _ckToken.getExternalPositionModules(component);
            if (externalModules.length > 0) {
                for (uint256 j = 0; j < externalModules.length; j++) {
                    int256 externalPositionUnit = _ckToken.getExternalPositionRealUnit(component, externalModules[j]);

                    require(externalPositionUnit > 0, "Only positive external unit positions are supported");

                    cumulativeUnits = cumulativeUnits.add(externalPositionUnit);
                }
            }

            totalUnits[i] = cumulativeUnits.toUint256();
        }

        return (components, totalUnits);        
    }

    /**
     * If a pre-issue hook has been configured, call the external-protocol contract. Pre-issue hook logic
     * can contain arbitrary logic including validations, external function calls, etc.
     * Note: All modules with external positions must implement ExternalPositionIssueHooks
     */
    function _callPreIssueHooks(
        ICKToken _ckToken,
        uint256 _quantity,
        address _caller,
        address _to
    )
        internal
        returns(address)
    {
        IManagerIssuanceHook preIssueHook = managerIssuanceHook[_ckToken];
        if (address(preIssueHook) != address(0)) {
            preIssueHook.invokePreIssueHook(_ckToken, _quantity, _caller, _to);
            return address(preIssueHook);
        }

        return address(0);
    }

    /**
     * For each component's external module positions, calculate the total notional quantity, and 
     * call the module's issue hook or redeem hook.
     * Note: It is possible that these hooks can cause the states of other modules to change.
     * It can be problematic if the a hook called an external function that called back into a module, resulting in state inconsistencies.
     */
    function _executeExternalPositionHooks(
        ICKToken _ckToken,
        uint256 _ckTokenQuantity,
        IERC20 _component,
        bool isIssue
    )
        internal
    {
        address[] memory externalPositionModules = _ckToken.getExternalPositionModules(address(_component));
        for (uint256 i = 0; i < externalPositionModules.length; i++) {
            if (isIssue) {
                IModuleIssuanceHook(externalPositionModules[i]).componentIssueHook(_ckToken, _ckTokenQuantity, _component, true);
            } else {
                IModuleIssuanceHook(externalPositionModules[i]).componentRedeemHook(_ckToken, _ckTokenQuantity, _component, true);
            }
        }
    }

    function _exchangeIssueTokenToDefaultPositions(ICKToken _ckToken, address _issueToken, address _component, uint256 _componentQuantity) internal returns(uint256, uint256) {
        uint256 issueTokenSpent;
        uint256 componentTokenReceived;
        if (_issueToken == _component) {
            // continue if issue token is component token
            issueTokenSpent = _componentQuantity;
            componentTokenReceived = _componentQuantity;
        } else if (wrapInfo[IERC20(_component)].underlyingToken == address(0)) {
            // For underlying tokens, exchange directly
            (issueTokenSpent, componentTokenReceived) = _trade(_ckToken, _issueToken, _component, _componentQuantity, false);
        } else {
            // For wrapped tokens, exchange to underlying tokens first and then wrap it
            WrapExecutionParams memory wrapExecutionParams = wrapInfo[IERC20(_component)];
            IWrapAdapter wrapAdapter = IWrapAdapter(getAndValidateAdapter(wrapExecutionParams.wrapAdapterName));
            uint256 underlyingTokenQuantity = wrapAdapter.getDepositUnderlyingTokenAmount(wrapExecutionParams.underlyingToken, _component, _componentQuantity);
            if (wrapExecutionParams.underlyingToken == wrapAdapter.ETH_TOKEN_ADDRESS()) {
                if (_issueToken != address(weth)) {
                    (issueTokenSpent, ) = _trade(_ckToken, _issueToken, address(weth), underlyingTokenQuantity, false);
                } else {
                    issueTokenSpent = underlyingTokenQuantity;
                }
                componentTokenReceived = _wrap(_ckToken, wrapExecutionParams.underlyingToken, _component, underlyingTokenQuantity, wrapExecutionParams.wrapAdapterName, true);
            } else {
                (issueTokenSpent,) = _trade(_ckToken, _issueToken, wrapExecutionParams.underlyingToken, underlyingTokenQuantity, false);
                componentTokenReceived = _wrap(_ckToken, wrapExecutionParams.underlyingToken, _component, underlyingTokenQuantity, wrapExecutionParams.wrapAdapterName, false);
            }
        }
        return (issueTokenSpent, componentTokenReceived);
    }

    function _exchangeDefaultPositionsToRedeemToken(ICKToken _ckToken, address _redeemToken, address _component, uint256 _componentQuantity) internal returns(uint256) {
        uint256 redeemTokenAcquired;
        if (_redeemToken == _component) {
            // continue if redeem token is component token
            redeemTokenAcquired = _componentQuantity;
        } else if (wrapInfo[IERC20(_component)].underlyingToken == address(0)) {
            // For underlying tokens, exchange directly
            
            (, redeemTokenAcquired) = _trade(_ckToken, _component, _redeemToken, _componentQuantity, true);
        } else {
            // For wrapped tokens, unwrap it and exchange underlying tokens to redeem tokens
            WrapExecutionParams memory wrapExecutionParams = wrapInfo[IERC20(_component)];
            IWrapAdapter wrapAdapter = IWrapAdapter(getAndValidateAdapter(wrapExecutionParams.wrapAdapterName));

            (uint256 underlyingReceived, uint256 unwrappedAmount) = 
            _unwrap(_ckToken, wrapExecutionParams.underlyingToken, _component, _componentQuantity, wrapExecutionParams.wrapAdapterName, wrapExecutionParams.underlyingToken == wrapAdapter.ETH_TOKEN_ADDRESS());

            if (wrapExecutionParams.underlyingToken == wrapAdapter.ETH_TOKEN_ADDRESS()) {
                (, redeemTokenAcquired) = _trade(_ckToken, address(weth), _redeemToken, underlyingReceived, true);                
            } else {
                (, redeemTokenAcquired) = _trade(_ckToken, wrapExecutionParams.underlyingToken, _redeemToken, underlyingReceived, true);                
            }    
        }
        return redeemTokenAcquired;
    }

    /**
     * Take snapshot of CKToken's balance of underlying and wrapped tokens.
     */
    function _snapshotTargetTokenBalance(
        ICKToken _ckToken,
        address _targetToken
    ) internal view returns(uint256) {
        uint256 targetTokenBalance = IERC20(_targetToken).balanceOf(address(_ckToken));
        return (targetTokenBalance);
    }

    /**
     * Validate post trade data.
     *
     * @param _tradeInfo                Struct containing trade information used in internal functions
     */
    function _validatePostTrade(TradeInfo memory _tradeInfo) internal view returns (uint256) {
        uint256 exchangedQuantity = IERC20(_tradeInfo.receiveToken)
        .balanceOf(address(_tradeInfo.ckToken))
        .sub(_tradeInfo.preTradeReceiveTokenBalance);

        require(
            exchangedQuantity >= _tradeInfo.totalReceiveQuantity, "Slippage too big"
        );
        return exchangedQuantity;
    }

    /**
     * Validate pre trade data. Check exchange is valid, token quantity is valid.
     *
     * @param _tradeInfo            Struct containing trade information used in internal functions
     */
    function _validatePreTradeData(TradeInfo memory _tradeInfo) internal view {
        require(_tradeInfo.totalSendQuantity > 0, "Token to sell must be nonzero");
        uint256 sendTokenBalance = IERC20(_tradeInfo.sendToken).balanceOf(address(_tradeInfo.ckToken));
        require(
            sendTokenBalance >= _tradeInfo.totalSendQuantity,
            "total send quantity cant be greater than existing"
        );
    }

    /**
     * Create and return TradeInfo struct
     *
     * @param _ckToken              Instance of the CKToken to trade
     * @param _exchangeAdapter      The exchange adapter in the integrations registry
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _exactQuantity        Exact token quantity during trade
     * @param _isSendTokenFixed     Indicate if the send token is fixed
     *
     * return TradeInfo             Struct containing data for trade
     */
    function _createTradeInfo(
        ICKToken _ckToken,
        IExchangeAdapter _exchangeAdapter,
        address _sendToken,
        address _receiveToken,
        uint256 _exactQuantity,
        bool _isSendTokenFixed
    )
        internal
        view
        returns (TradeInfo memory)
    {
        uint256 thresholdAmount;
        address[] memory path;
        if (_sendToken == address(weth) || _receiveToken == address(weth)) {
            path = new address[](2);
            path[0] = _sendToken;
            path[1] = _receiveToken;
            // uint256[] memory thresholdAmounts = _isSendTokenFixed ? _exchangeAdapter.getMinAmountsOut(_exactQuantity, path) : _exchangeAdapter.getMaxAmountsIn(_exactQuantity, path);
            // thresholdAmount = _isSendTokenFixed ? thresholdAmounts[1] : thresholdAmounts[0];
        } else {
            path = new address[](3);
            path[0] = _sendToken;
            path[1] = address(weth);
            path[2] = _receiveToken;
            // uint256[] memory thresholdAmounts = _isSendTokenFixed ? _exchangeAdapter.getMinAmountsOut(_exactQuantity, path) : _exchangeAdapter.getMaxAmountsIn(_exactQuantity, path);
            // thresholdAmount = _isSendTokenFixed ? thresholdAmounts[2] : thresholdAmounts[0];
        }

        TradeInfo memory tradeInfo;
        tradeInfo.ckToken = _ckToken;
        tradeInfo.exchangeAdapter = _exchangeAdapter;
        tradeInfo.sendToken = _sendToken;
        tradeInfo.receiveToken = _receiveToken;
        tradeInfo.totalSendQuantity =  _exactQuantity;
        tradeInfo.totalReceiveQuantity = 0;
        tradeInfo.preTradeSendTokenBalance = _snapshotTargetTokenBalance(_ckToken, _sendToken);
        tradeInfo.preTradeReceiveTokenBalance = _snapshotTargetTokenBalance(_ckToken, _receiveToken);
        tradeInfo.data = _isSendTokenFixed ? _exchangeAdapter.generateDataParam(path, true) : _exchangeAdapter.generateDataParam(path, false);
        return tradeInfo;
    }

    /**
     * Calculate the exchange execution price based on send and receive token amount.
     *
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _isSendTokenFixed     Indicate if the send token is fixed
     * @param _exactQuantity        Exact token quantity during trade
     * @param _thresholdAmount      Max/Min amount of token to send/receive
     *
     * return uint256               Exchange execution price
     */
    function _calculateExchangeExecutionPrice(address _sendToken, address _receiveToken, bool _isSendTokenFixed,
        uint256 _exactQuantity, uint256 _thresholdAmount) internal view returns (uint256)
    {
        uint256 sendQuantity = _isSendTokenFixed ? _exactQuantity : _thresholdAmount;
        uint256 receiveQuantity = _isSendTokenFixed ? _thresholdAmount : _exactQuantity;
        uint256 normalizedSendQuantity = sendQuantity.preciseDiv(uint256(10).safePower(uint256(ERC20(_sendToken).decimals())));
        uint256 normalizedReceiveQuantity = receiveQuantity.preciseDiv(uint256(10).safePower(uint256(ERC20(_receiveToken).decimals())));
        return normalizedReceiveQuantity.preciseDiv(normalizedSendQuantity);
    }

    /**
     * Invoke approve for send token, get method data and invoke trade in the context of the CKToken.
     *
     * @param _ckToken              Instance of the CKToken to trade
     * @param _exchangeAdapter      Exchange adapter in the integrations registry
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _sendQuantity         Units of token in CKToken sent to the exchange
     * @param _receiveQuantity      Units of token in CKToken received from the exchange
     * @param _data                 Arbitrary bytes to be used to construct trade call data
     */
    function _executeTrade(
        ICKToken _ckToken,
        IExchangeAdapter _exchangeAdapter,
        address _sendToken,
        address _receiveToken,
        uint256 _sendQuantity,
        uint256 _receiveQuantity,
        bytes memory _data
    )
        internal
    {
        // Get spender address from exchange adapter and invoke approve for exact amount on CKToken
        _ckToken.invokeApprove(
            _sendToken,
            _exchangeAdapter.getSpender(),
            _sendQuantity
        );

        (
            address targetExchange,
            uint256 callValue,
            bytes memory methodData
        ) = _exchangeAdapter.getTradeCalldata(
            _sendToken,
            _receiveToken,
            address(_ckToken),
            _sendQuantity,
            _receiveQuantity,
            _data
        );

        _ckToken.invoke(targetExchange, callValue, methodData);
    }

    /**
     * Executes a trade on a supported DEX.
     *
     * @param _ckToken              Instance of the CKToken to trade
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _exactQuantity        Exact Quantity of token in CKToken to be sent or received from the exchange
     * @param _isSendTokenFixed     Indicate if the send token is fixed
     */
    function _trade(
        ICKToken _ckToken,
        address _sendToken,
        address _receiveToken,
        uint256 _exactQuantity,
        bool _isSendTokenFixed
    )
        internal
        returns (uint256, uint256)
    {
        if (address(_sendToken) == address(_receiveToken)) {
            return (_exactQuantity, _exactQuantity);
        }
        TradeInfo memory tradeInfo = _createTradeInfo(
            _ckToken,
            IExchangeAdapter(getAndValidateAdapter(exchangeInfo[IERC20(_receiveToken)])),
            _sendToken,
            _receiveToken,
            _exactQuantity,
            _isSendTokenFixed
        );
        _validatePreTradeData(tradeInfo);
        _executeTrade(tradeInfo.ckToken, tradeInfo.exchangeAdapter, tradeInfo.sendToken, tradeInfo.receiveToken, tradeInfo.totalSendQuantity, tradeInfo.totalReceiveQuantity, tradeInfo.data);
        _validatePostTrade(tradeInfo);
        uint256 totalSendQuantity = tradeInfo.preTradeSendTokenBalance.sub(_snapshotTargetTokenBalance(_ckToken, _sendToken));
        uint256 totalReceiveQuantity = _snapshotTargetTokenBalance(_ckToken, _receiveToken).sub(tradeInfo.preTradeReceiveTokenBalance);
        emit ComponentExchanged(
            _ckToken,
            _sendToken,
            _receiveToken,
            tradeInfo.exchangeAdapter,
            totalSendQuantity,
            totalReceiveQuantity
        );
        return (totalSendQuantity, totalReceiveQuantity);
    }

    /**
     * Instructs the CKToken to wrap an underlying asset into a wrappedToken via a specified adapter.
     *
     * @param _ckToken              Instance of the CKToken
     * @param _underlyingToken      Address of the component to be wrapped
     * @param _wrappedToken         Address of the desired wrapped token
     * @param _underlyingQuantity   Quantity of underlying tokens to wrap
     * @param _integrationName      Name of wrap module integration (mapping on integration registry)
     */
    function _wrap(
        ICKToken _ckToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingQuantity,
        string memory _integrationName,
        bool _usesEther
    )
        internal
        returns (uint256)
    {
        (
        uint256 notionalUnderlyingWrapped,
        uint256 notionalWrapped
        ) = _validateAndWrap(
            _integrationName,
            _ckToken,
            _underlyingToken,
            _wrappedToken,
            _underlyingQuantity,
            _usesEther // does not use Ether
        );

        emit ComponentWrapped(
            _ckToken,
            _underlyingToken,
            _wrappedToken,
            notionalUnderlyingWrapped,
            notionalWrapped,
            _integrationName
        );
        return notionalWrapped;
    }

    /**
     * MANAGER-ONLY: Instructs the CKToken to unwrap a wrapped asset into its underlying via a specified adapter.
     *
     * @param _ckToken              Instance of the CKToken
     * @param _underlyingToken      Address of the underlying asset
     * @param _wrappedToken         Address of the component to be unwrapped
     * @param _wrappedQuantity      Quantity of wrapped tokens in Position units
     * @param _integrationName      ID of wrap module integration (mapping on integration registry)
     */
    function _unwrap(
        ICKToken _ckToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedQuantity,
        string memory _integrationName,
        bool _usesEther
    )
        internal returns (uint256, uint256)
    {
        (
        uint256 notionalUnderlyingUnwrapped,
        uint256 notionalUnwrapped
        ) = _validateAndUnwrap(
            _integrationName,
            _ckToken,
            _underlyingToken,
            _wrappedToken,
            _wrappedQuantity,
            _usesEther // uses Ether
        );

        emit ComponentUnwrapped(
            _ckToken,
            _underlyingToken,
            _wrappedToken,
            notionalUnderlyingUnwrapped,
            notionalUnwrapped,
            _integrationName
        );

        return (notionalUnderlyingUnwrapped, notionalUnwrapped);
    }

    /**
     * The WrapModule approves the underlying to the 3rd party
     * integration contract, then invokes the CKToken to call wrap by passing its calldata along. When raw ETH
     * is being used (_usesEther = true) WETH position must first be unwrapped and underlyingAddress sent to
     * adapter must be external protocol's ETH representative address.
     *
     * Returns notional amount of underlying tokens and wrapped tokens that were wrapped.
     */
    function _validateAndWrap(
        string memory _integrationName,
        ICKToken _ckToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingQuantity,
        bool _usesEther
    )
        internal
        returns (uint256, uint256)
    {
        uint256 preActionUnderlyingNotional;
        // Snapshot pre wrap balances
        uint256 preActionWrapNotional = _snapshotTargetTokenBalance(_ckToken, _wrappedToken);

        IWrapAdapter wrapAdapter = IWrapAdapter(getAndValidateAdapter(_integrationName));

        address snapshotToken = _usesEther ? address(weth) : _underlyingToken;
        _validateInputs(_ckToken, snapshotToken, _underlyingQuantity);
        preActionUnderlyingNotional = _snapshotTargetTokenBalance(_ckToken, snapshotToken);

        // Execute any pre-wrap actions depending on if using raw ETH or not
        if (_usesEther) {
            _ckToken.invokeUnwrapWETH(address(weth), _underlyingQuantity);
        } else {
            address spender = wrapAdapter.getWrapSpenderAddress(_underlyingToken, _wrappedToken);
            _ckToken.invokeApprove(_underlyingToken, spender, _underlyingQuantity.add(1));
        }

        // Get function call data and invoke on CKToken
        _createWrapDataAndInvoke(
            _ckToken,
            wrapAdapter,
            _usesEther ? wrapAdapter.ETH_TOKEN_ADDRESS() : _underlyingToken,
            _wrappedToken,
            _underlyingQuantity
        );

        // Snapshot post wrap balances
        uint256 postActionUnderlyingNotional = _snapshotTargetTokenBalance(_ckToken, snapshotToken);
        uint256 postActionWrapNotional = _snapshotTargetTokenBalance(_ckToken, _wrappedToken);
        return (
            preActionUnderlyingNotional.sub(postActionUnderlyingNotional),
            postActionWrapNotional.sub(preActionWrapNotional)
        );
    }

    /**
     * The WrapModule calculates the total notional wrap token to unwrap, then invokes the CKToken to call
     * unwrap by passing its calldata along. When raw ETH is being used (_usesEther = true) underlyingAddress
     * sent to adapter must be set to external protocol's ETH representative address and ETH returned from
     * external protocol is wrapped.
     *
     * Returns notional amount of underlying tokens and wrapped tokens unwrapped.
     */
    function _validateAndUnwrap(
        string memory _integrationName,
        ICKToken _ckToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedTokenQuantity,
        bool _usesEther
    )
        internal
        returns (uint256, uint256)
    {
        _validateInputs(_ckToken, _wrappedToken, _wrappedTokenQuantity);

        // Snapshot pre wrap balance
        address snapshotToken = _usesEther ? address(weth) : _underlyingToken;
        uint256 preActionUnderlyingNotional = _snapshotTargetTokenBalance(_ckToken, snapshotToken);
        uint256 preActionWrapNotional = _snapshotTargetTokenBalance(_ckToken, _wrappedToken);

        IWrapAdapter wrapAdapter = IWrapAdapter(getAndValidateAdapter(_integrationName));
        address unWrapSpender = wrapAdapter.getUnwrapSpenderAddress(_underlyingToken, _wrappedToken);
        _ckToken.invokeApprove(_wrappedToken, unWrapSpender, _wrappedTokenQuantity);
        
        // Get function call data and invoke on CKToken
        _createUnwrapDataAndInvoke(
            _ckToken,
            wrapAdapter,
            _usesEther ? wrapAdapter.ETH_TOKEN_ADDRESS() : _underlyingToken,
            _wrappedToken,
            _wrappedTokenQuantity
        );

        // immediately wrap to WTH after getting back ETH
        if (_usesEther) {
            _ckToken.invokeWrapWETH(address(weth), address(_ckToken).balance);
        }
        
        // Snapshot post wrap balances
        uint256 postActionUnderlyingNotional = _snapshotTargetTokenBalance(_ckToken, snapshotToken);
        uint256 postActionWrapNotional = _snapshotTargetTokenBalance(_ckToken, _wrappedToken);
        return (
            postActionUnderlyingNotional.sub(preActionUnderlyingNotional),
            preActionWrapNotional.sub(postActionWrapNotional)
        );
    }

    /**
     * Validates the wrap operation is valid. In particular, the following checks are made:
     * - The position is Default
     * - The position has sufficient units given the transact quantity
     * - The transact quantity > 0
     *
     * It is expected that the adapter will check if wrappedToken/underlyingToken are a valid pair for the given
     * integration.
     */
    function _validateInputs(
        ICKToken _ckToken,
        address _component,
        uint256 _quantity
    )
        internal
        view
    {
        require(_quantity > 0, "component quantity must be > 0");
        require(_snapshotTargetTokenBalance(_ckToken, _component) >= _quantity, "quantity cant be greater than existing");
    }

    /**
     * Create the calldata for wrap and then invoke the call on the CKToken.
     */
    function _createWrapDataAndInvoke(
        ICKToken _ckToken,
        IWrapAdapter _wrapAdapter,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _notionalUnderlying
    ) internal {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _wrapAdapter.getWrapCallData(
            _underlyingToken,
            _wrappedToken,
            _notionalUnderlying
        );

        _ckToken.invoke(callTarget, callValue, callByteData);
    }

    /**
     * Create the calldata for unwrap and then invoke the call on the CKToken.
     */
    function _createUnwrapDataAndInvoke(
        ICKToken _ckToken,
        IWrapAdapter _wrapAdapter,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _notionalUnderlying
    ) internal {
        (
            address callTarget,
            uint256 callValue,
            bytes memory callByteData
        ) = _wrapAdapter.getUnwrapCallData(
            _underlyingToken,
            _wrappedToken,
            _notionalUnderlying
        );

        _ckToken.invoke(callTarget, callValue, callByteData);
    }
}