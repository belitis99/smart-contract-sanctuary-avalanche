/**
 *Submitted for verification at snowtrace.io on 2021-11-10
*/

pragma solidity 0.6.12;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}
library EnumerableSet {
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

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, 'EnumerableSet: index out of bounds');
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
contract Ownable is Context {
    address private _owner;
    //  MasterChef contract that can mint the reward token
    address private _chef;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IWETH{
     function transfer(address recipient, uint256 amount) external;
     function withdraw(uint wad) external;
}
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');
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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}
interface ILibToken is IBEP20 {
    function setChef(address chef) external;
    function mint(address _to, uint256 _amount) external;
}
interface IUniswapRouter {
    function WAVAX() external view returns (uint256);
    function WETH() external view returns (uint256);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}
interface IUniswapPair {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

}
interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}
// SPDX-License-Identifier: MIT
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

    constructor() public {
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
contract APYCalcualte{
    
    using SafeMath for uint256;
    address public USD;
    address public LBRE;
    IUniswapFactory public factory;
    MasterChef public chef;

    constructor(address _USD, address _LBRE, address _factory, address payable _chef)public{
        USD = _USD;
        LBRE = _LBRE;
        factory = IUniswapFactory(_factory);
        chef = MasterChef(_chef);
    }
   function USDToToken0(address _token0)public view returns(uint256){
        address token0USD = factory.getPair(_token0, USD);
        IUniswapPair token0USDPair = IUniswapPair(token0USD);
        IBEP20 usd = token0USDPair.token0() == USD ?IBEP20(token0USDPair.token0()) :IBEP20(token0USDPair.token1());
        IBEP20 token0 = token0USDPair.token0() == USD ?IBEP20(token0USDPair.token1()) :IBEP20(token0USDPair.token0());
        (uint112 reserve0, uint112 reserve1,) = token0USDPair.getReserves(); 
        uint256 res0 = token0USDPair.token0() == USD ?uint256(reserve1) * (10**uint256(usd.decimals())) :uint256(reserve0) * (10**uint256(usd.decimals()));
        uint256 resUSD = token0USDPair.token0() == USD ?uint256(reserve0) * (10**uint256(token0.decimals())) :uint256(reserve1) * (10**uint256(token0.decimals()));
        return res0.mul(1e18).div(resUSD);
    }
    function LbreToUSD(uint256 input)public view returns(uint256){
        address lbreUSD = factory.getPair(USD, LBRE);
        IUniswapPair lbreUSDPair = IUniswapPair(lbreUSD);
        IBEP20 usd = lbreUSDPair.token0() == USD ?IBEP20(lbreUSDPair.token0()) :IBEP20(lbreUSDPair.token1());
        IBEP20 lbre = lbreUSDPair.token0() == USD ?IBEP20(lbreUSDPair.token1()) :IBEP20(lbreUSDPair.token0());
        (uint112 reserve0, uint112 reserve1,) = lbreUSDPair.getReserves(); 
        uint256 res0 = lbreUSDPair.token0() == USD ?uint256(reserve1) * (10**uint256(usd.decimals())) :uint256(reserve0) * (10**uint256(usd.decimals()));
        uint256 resUSD = lbreUSDPair.token0() == USD ?uint256(reserve0) * (10**uint256(lbre.decimals())) :uint256(reserve1) * (10**uint256(lbre.decimals()));
        return input.mul(resUSD).div(res0);
    }
    function APYC(uint8 _pid) public view returns(uint256 lpOutput, uint256 rewardPerBlock){
        // PoolInfo storage pool = chef.poolInfo[_pid];
        (IBEP20 lp,address[]memory lpPath,uint256 allocPoint) = chef.forAPYC(_pid);
        // IBEP20 lp =  chef.getPoolLP(_pid);
        // address[] memory lpPath = chef.getPath(_pid);
        // uint256 allocPoint = chef.getAllocPoint(_pid);
        uint256 totalAllocPoint = chef.totalAllocPoint(); 
        uint256 libPerBlock = chef.libPerBlock();
        IBEP20 token0 = IBEP20(lpPath[0]);
        if(_pid != 0){
            IUniswapPair pair = IUniswapPair(address(lp));
            uint256 USDToToken0 = USDToToken0(address(token0));
            uint256 token0input = USDToToken0.div(2);
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves(); 
            uint256 lpOutput = (lpPath[0] == pair.token0()) ?token0input * pair.totalSupply() / uint256(reserve0) 
            :token0input * pair.totalSupply() / uint256(reserve1);
            uint256 rewardPerBlock = lpOutput.mul(libPerBlock).div(lp.balanceOf(address(chef)));
            rewardPerBlock = rewardPerBlock.mul(allocPoint).div(totalAllocPoint);
            rewardPerBlock = LbreToUSD(rewardPerBlock);
            return (lpOutput, rewardPerBlock);
        }else{
            uint256 libInput = 1e18;
            rewardPerBlock = libInput.mul(libPerBlock).div(chef.totalStaked());
            rewardPerBlock = rewardPerBlock.mul(allocPoint).div(totalAllocPoint);
            return (0, rewardPerBlock);
        }
    }
}
contract MasterChef is Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        address[] lpPath;
        uint256 accLibPerShare; // Accumulated LIBs per share, times 1e12. See below.
        bool isETHPair; // non-Libre LP will be charged 5% fee on withdraw
    }
    // The LIB TOKEN!
    ILibToken public lib;
    // Dev address.
    address public devaddr;
    // Lib tokens created per block.
    uint256 public libPerBlock = 1*10**18;
    // Lib tokens burn per block.
    // uint256 public burnPerBlock = 3*10**18;
    IUniswapRouter public uniRouter;
    IUniswapRouter public libreRouter;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    //set true after a new lp be added
    mapping (address=>bool) public isPooled;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    uint256 public totalStaked = 0;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 token1Amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    IWETH public WETH;
    constructor(
        address[]memory _lib,
        address _devaddr,
        address _libRouter,
        address _uniRouter,
        uint256 _startBlock
    ) public {
        require(_devaddr != address(0),"_devaddr cannot be 0");
        lib = ILibToken(_lib[0]);
        libreRouter = IUniswapRouter(_libRouter);
        uniRouter = IUniswapRouter(_uniRouter);
        devaddr = _devaddr;
        startBlock = _startBlock;
        totalAllocPoint = totalAllocPoint.add(10);
        WETH = IWETH(uniRouter.WAVAX());
        poolInfo.push(
            PoolInfo({
                lpToken: lib,
                allocPoint: 10,
                lpPath:_lib,
                lastRewardBlock: startBlock,
                accLibPerShare: 0,
                isETHPair: false
            })
        );
    }
    // function APY_config(address _APY)external onlyOwner{
    //     require(_APY != address(0),"_APY cannot be 0");
    //     APY = APYCalcualte(_APY);
    // }
    // function poolLength() external view returns (uint256) {
    //     return poolInfo.length;
    // }

    function setRouter(address _router, uint8 index)external onlyOwner{
        require(_router != address(0),"_uniRouter cannot be 0");
        if(index == 0) uniRouter = IUniswapRouter(_router);
        else if(index == 1)libreRouter = IUniswapRouter(_router);
    }
    function forAPYC(uint8 _pid)external view returns(IBEP20, address[]memory, uint256){
        return (poolInfo[_pid].lpToken, poolInfo[_pid].lpPath, poolInfo[_pid].allocPoint);
    }
    // function getPoolLP(uint8 _pid)external view returns(IBEP20){
    //     return poolInfo[_pid].lpToken;
    // }
    // function getPath(uint8 _pid)external view returns(address[] memory){
    //     return poolInfo[_pid].lpPath;
    // }
    // function getAllocPoint(uint8 _pid)external view returns(uint256){
    //     return poolInfo[_pid].allocPoint;
    // }
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        address[] memory _lpPath,
        bool _withUpdate,
        bool _isETHPair
    ) external onlyOwner {
        require(!isPooled[address(_lpToken)]);
        isPooled[address(_lpToken)] = true;
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        IBEP20 token0 = IBEP20(_lpPath[0]);
        IBEP20 token1 = IBEP20(_lpPath[1]);
        IUniswapPair pair = IUniswapPair(address(_lpToken));
        require((pair.token0() == _lpPath[0] && pair.token1() == _lpPath[1]) || (pair.token0() == _lpPath[1] && pair.token1() == _lpPath[0]), "pair does not exist");
        token0.approve(address(uniRouter),2**95);
        token1.approve(address(uniRouter),2**95);
        token0.approve(address(libreRouter),2**95);
        token1.approve(address(libreRouter),2**95);
        _lpToken.approve(address(uniRouter),2**95);
        _lpToken.approve(address(libreRouter),2**95);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lpPath:_lpPath,
                lastRewardBlock: lastRewardBlock,
                accLibPerShare: 0,
                isETHPair: _isETHPair
            })
        );
    }
    
    // Update the given pool's allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner validatePoolByPid(_pid){
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    // function setMigrator(IMigratorChef _migrator) public onlyOwner {
    //     migrator = _migrator;
    // }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    // function migrate(uint256 _pid) public {
    //     require(address(migrator) != address(0), "migrate: no migrator");
    //     PoolInfo storage pool = poolInfo[_pid];
    //     IBEP20 lpToken = pool.lpToken;
    //     uint256 bal = lpToken.balanceOf(address(this));
    //     lpToken.safeApprove(address(migrator), bal);
    //     IBEP20 newLpToken = migrator.migrate(lpToken);
    //     require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
    //     pool.lpToken = newLpToken;
    // }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256){
        require(_from >= startBlock, "_from can not less than startBlock!");
        return _to.sub(_from);
    }

    // View function to see pending SUSHIs on frontend.
    function pendingLib(uint256 _pid, address _user)
        external
        view validatePoolByPid(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accLibPerShare = pool.accLibPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 libReward =  multiplier.mul(libPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accLibPerShare = accLibPerShare.add(
                libReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accLibPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePoolByPid(_pid){
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = _pid == 0 ?totalStaked :pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 libReward =
            multiplier.mul(libPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        lib.mint(address(this),libReward);
        pool.accLibPerShare = pool.accLibPerShare.add(
            libReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }
    function stake(uint256 _amount) public nonReentrant{
        lib.transferFrom(msg.sender, address(this), _amount);
        updatePool(0);
        totalStaked = totalStaked.add(_amount);
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 fee = pending.mul(2).div(100);

            safeLibreTransfer(msg.sender, pending.sub(fee));
            safeLibreTransfer(devaddr, fee);
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        emit Deposit(msg.sender, 0, _amount, 0);
    }
    function unstake(uint256 _amount)public nonReentrant{
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        totalStaked = totalStaked.sub(_amount);
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending =
            user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                user.rewardDebt
            );
        uint256 fee = pending.mul(2).div(100);

        // if(!pool.isLibrePair){// burn 5% of Libre reward
        //     lib.burn(address(this),pending.mul(5).div(100));
        //     pending = pending.mul(95).div(100);
        // }
        user.amount = user.amount.sub(_amount);
        safeLibreTransfer(msg.sender, pending.sub(fee));
        safeLibreTransfer(devaddr, fee);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        // pool.lpToken.safeTransfer(address(msg.sender), _amount);
        safeLibreTransfer(address(msg.sender),_amount);
        emit Withdraw(msg.sender, 0, _amount);
    }
    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount, uint8 _slippage) public validatePoolByPid(_pid) nonReentrant payable{
        require(_pid>0,"pool 0 is for staking");
        require(_slippage<=20,"slippage range not greater than 2%");
        // require(_slippage<0,"slippage value must");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            uint256 fee = pending.mul(2).div(100);

            safeLibreTransfer(msg.sender, pending.sub(fee));
            safeLibreTransfer(devaddr, fee);
        }
        uint256 lpBefore = pool.lpToken.balanceOf(address(this));
        if(pool.isETHPair) _amount = msg.value;
        uint256 token1Amount=_swap(msg.sender, pool, _amount,_slippage);
        uint256 lpAmount = pool.lpToken.balanceOf(address(this)).sub(lpBefore);

        uint256 fee = lpAmount.mul(2).div(100);
        lpAmount = lpAmount.sub(fee);
        pool.lpToken.transfer(devaddr,fee);
        user.amount = user.amount.add(lpAmount);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount, token1Amount);
    }
    function _swap(address payable _to, PoolInfo storage pool, uint256 _amount, uint8 _slippage)private returns (uint256){
        IBEP20 token0 = IBEP20(pool.lpPath[0]);
        IBEP20 token1 = IBEP20(pool.lpPath[1]);
        uint256 token0init = pool.isETHPair?address(this).balance :token0.balanceOf(address(this));
        if(!pool.isETHPair)token0.transferFrom(_to, address(this), _amount);
    
        uint256 token1Before = token1.balanceOf(address(this));

        uint256 minAmount = _slippageCalculate(token0, token1, _amount.div(2), _slippage);
        if(pool.isETHPair) uniRouter.swapExactAVAXForTokens{value: _amount.div(2)}(minAmount, pool.lpPath, address(this), block.timestamp);
        else uniRouter.swapExactTokensForTokens(_amount.div(2), minAmount, pool.lpPath, address(this), block.timestamp);
       
        uint256 token0Amount = pool.isETHPair ?_amount.div(2) :token0init.add(_amount).sub(token0.balanceOf(address(this))); 
        uint256 token1Amount = token1.balanceOf(address(this)).sub(token1Before);
        if(pool.isETHPair) libreRouter.addLiquidityETH{value: token0Amount}(address(token1),token1Amount,0,0,address(this), block.timestamp);
        else libreRouter.addLiquidity(address(token0), address(token1), token0Amount, token1Amount, 0 , 0, address(this), block.timestamp);
        uint256 token0leftOver = pool.isETHPair?address(this).balance.sub(token0init.sub(_amount)):token0.balanceOf(address(this)).sub(token0init); 
        uint256 token1leftOver = token1.balanceOf(address(this)).sub(token1Before); 
        
        if(token0leftOver>0 && !pool.isETHPair)token0.transfer(_to, token0leftOver);
        else if(token0leftOver>0 && pool.isETHPair)_to.transfer(token0leftOver);
        if(token1leftOver>0)token1.transfer(_to, token1leftOver);
        return token1Amount;
    }
    function _slippageCalculate(IBEP20 token0, IBEP20 token1, uint256 input, uint8 _slippage)private view returns(uint256){
        address[] memory t = new address[](2);
        t[0] = address(token0);
        t[1] = address(token1);
        // uint256 exceptedAmount = uniRouter.getAmountsOut(input, t)[1].mul(1000-_slippage).div(1000);
        return uniRouter.getAmountsOut(input, t)[1].mul(1000-_slippage).div(1000);
    }
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public validatePoolByPid(_pid) nonReentrant payable{
        require(_pid>0,"pool 0 is for staking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IBEP20 token0 = IBEP20(pool.lpPath[0]);
        IBEP20 token1 = IBEP20(pool.lpPath[1]);

        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accLibPerShare).div(1e12).sub(
                user.rewardDebt
            );
        uint256 fee = pending.mul(2).div(100);
        uint256 token0Before = token0.balanceOf(address(this));
        uint256 token1Before = token1.balanceOf(address(this));

        libreRouter.removeLiquidity(address(token0), address(token1), _amount, 0 , 0, address(this), block.timestamp);
        uint256 token0Amount = token0.balanceOf(address(this)).sub(token0Before);
        uint256 token1Amount = token1.balanceOf(address(this)).sub(token1Before);
        user.amount = user.amount.sub(_amount);
        safeLibreTransfer(msg.sender, pending.sub(fee));
        safeLibreTransfer(devaddr, fee);
        user.rewardDebt = user.amount.mul(pool.accLibPerShare).div(1e12);
        if(pool.isETHPair){
            WETH.withdraw(uint(token0Amount));
            msg.sender.transfer(token0Amount);
            // token0.transfer(address(msg.sender),token0Amount);
        }
        else token0.transfer(address(msg.sender),token0Amount);
        token1.transfer(address(msg.sender),token1Amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    receive() external payable {}
    
    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough Libres.
    function safeLibreTransfer(address _to, uint256 _amount) internal {
        uint256 libBal = lib.balanceOf(address(this));
        if (_amount > libBal) {
            lib.transfer(_to, libBal);
        } else {
            lib.transfer(_to, _amount);
        }
    }

    // function APYC(uint8 _pid) public view returns(uint256 lpOutput, uint256 rewardPerBlock){
    //     PoolInfo storage pool = poolInfo[_pid];
    //     IBEP20 lp =  pool.lpToken;
    //     IBEP20 token0 = IBEP20(pool.lpPath[0]);

    //     if(_pid != 0){
    //         IUniswapPair pair = IUniswapPair(address(lp));
    //         uint256 USDToToken0 = APY.USDToToken0(address(token0));
    //         uint256 token0input = USDToToken0.div(2);
    //         (uint112 reserve0, uint112 reserve1,) = pair.getReserves(); 
    //         uint256 lpOutput = (pool.lpPath[0] == pair.token0()) ?token0input * pair.totalSupply() / uint256(reserve0) 
    //         :token0input * pair.totalSupply() / uint256(reserve1);
    //         uint256 rewardPerBlock = lpOutput.mul(libPerBlock).div(lp.balanceOf(address(this)));
    //         rewardPerBlock = rewardPerBlock.mul(pool.allocPoint).div(totalAllocPoint);
    //         rewardPerBlock = APY.LbreToUSD(rewardPerBlock);
    //         return (lpOutput, rewardPerBlock);
    //     }else{
    //         uint256 libInput = 1e18;
    //         rewardPerBlock = libInput.mul(libPerBlock).div(totalStaked);
    //         rewardPerBlock = rewardPerBlock.mul(pool.allocPoint).div(totalAllocPoint);
    //         return (0, rewardPerBlock);
    //     }
    // }
        // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(_pid>0) pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        else{
            safeLibreTransfer(address(msg.sender),user.amount);
            totalStaked = totalStaked.sub(user.amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        
        user.amount = 0;
        user.rewardDebt = 0;
    }
    modifier validatePoolByPid(uint256 _pid){
        require(_pid<poolInfo.length, "Pool does not exist");
        _;
    }
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}