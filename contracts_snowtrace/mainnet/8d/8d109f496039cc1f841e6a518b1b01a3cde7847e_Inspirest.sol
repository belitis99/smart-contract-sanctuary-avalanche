/**
 *Submitted for verification at snowtrace.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        assembly { codehash := extcodehash(account) }
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
contract Ownable is Context {

    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Returns the address of the current owner.
     */
    //function Owner() public view returns (address) {
     //   return _owner;
    //}

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

contract Inspirest is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => bool) public preSaleIQ1Users;
    mapping(address => bool) public preSaleIQ2Users;
    mapping(address => bool) public preSaleIQ3Users;
    mapping(address => bool) public preSaleIQ4Users;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    string  private _NAME;
    string  private _SYMBOL;
    uint256 private _DECIMALS;
	address public App_Fees_Address;
	address private tokenOwner;
   
    uint256 private _MAX = ~uint256(0);
    uint256 private _DECIMALFACTOR;
    uint256 private _GRANULARITY = 100;
    
    uint256 private _tTotal;
    uint256 private _rTotal;
    
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tAppTotal;
    
    uint256 private     _TAX_FEE;
    uint256 public    _Burn_Fee;
    uint256 public _App_Fees;

    // Track original fees to bypass fees for app account
    uint256 private ORIG_TAX_FEE;
    uint256 private ORIG_Burn_Fee;
    uint256 private ORIG_App_Fees;

    event PresaleIQ1WalletStatus(address usera);
    event PresaleIQ2WalletStatus(address userb);
    event PresaleIQ3WalletStatus(address userc);
    event PresaleIQ4WalletStatus(address userd);


    constructor ()  {
		_NAME = "Inspirest Metaverse";
		_SYMBOL = "iREST";
		_DECIMALS = 9;
		_DECIMALFACTOR = 10 ** _DECIMALS;
		_tTotal = 10000000000 * _DECIMALFACTOR;
		_rTotal = (_MAX - (_MAX % _tTotal));
		_TAX_FEE = 0* 100; 
        _Burn_Fee = 0* 100;
		_App_Fees = 0* 100;
		ORIG_TAX_FEE = _TAX_FEE;
		ORIG_Burn_Fee = _Burn_Fee;
		ORIG_App_Fees = _App_Fees;
        tokenOwner = 0xB0475AC38031466f6D5AEa6BD8038c230095f311;
		App_Fees_Address = 0x95600cB60Ca2490df136C7B2Fb5D1D864E2AB7aF;
		_owner = tokenOwner;
        _rOwned[tokenOwner] = _rTotal;
        emit Transfer(address(0),tokenOwner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _NAME;
    }

    function Symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint8) {
        return uint8(_DECIMALS);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Inspirest: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Inspirest: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function Total_Burn_Fees() public view returns (uint256) {
        return _tBurnTotal;
    }
    
    function Total_App_Fees() public view returns (uint256) {
        return _tAppTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }


    // PreSale - I Q1
    // 30 April 2022 Unlocked
    
    function setPresaleIQ1Wallet(address usera) external onlyOwner {
        if (!preSaleIQ1Users[usera]) {
            preSaleIQ1Users[usera] = true;
           emit PresaleIQ1WalletStatus(usera);
            }
    
    }

    function isPresaleIQ1Wallet(address usera) private  returns(bool) {
        if (preSaleIQ1Users[usera]) {
                if(block.timestamp <= 1651309200){ // Sat Apr 30 2022 09:00:00 GMT+0000
                    return true;
            }else{
            delete preSaleIQ1Users[usera];  
            return false;              
            }
    }else{
        return false;
    }
    }

    function getPresaleIQ1WalletStatus(address usera) public view returns(bool) {
        return preSaleIQ1Users[usera];
    }


    // PreSale - I Q2
    // 30 July 2022 Unlocked
    
    function setPresaleIQ2Wallet(address userb) external onlyOwner {
        if (!preSaleIQ2Users[userb]) {
            preSaleIQ2Users[userb] = true;
           emit PresaleIQ2WalletStatus(userb);
            }
    
    }

    function isPresaleIQ2Wallet(address userb) private  returns(bool) {
        if (preSaleIQ2Users[userb]) {
                if(block.timestamp <= 1659171600){ // Sat Jul 30 2022 09:00:00 GMT+0000
                    return true;
            }else{
            delete preSaleIQ2Users[userb];  
            return false;              
            }
    }else{
        return false;
    }
    }

    function getPresaleIQ2WalletStatus(address userb) public view returns(bool) {
        return preSaleIQ1Users[userb];
    }


    // PreSale - I Q3
    // 30 October 2022 Unlocked
    
    function setPresaleIQ3Wallet(address userc) external onlyOwner {
        if (!preSaleIQ3Users[userc]) {
            preSaleIQ3Users[userc] = true;
           emit PresaleIQ3WalletStatus(userc);
            }
    
    }

    function isPresaleIQ3Wallet(address userc) private  returns(bool) {
        if (preSaleIQ3Users[userc]) {
                if(block.timestamp <= 1667120400){ // Sun Oct 30 2022 09:00:00 GMT+0000
                    return true;
            }else{
            delete preSaleIQ3Users[userc];  
            return false;              
            }
    }else{
        return false;
    }
    }

    function getPresaleIQ3WalletStatus(address userc) public view returns(bool) {
        return preSaleIQ3Users[userc];
    }


    // PreSale - I Q4
    // 30 January 2023 Unlocked
    
    function setPresaleIQ4Wallet(address userd) external onlyOwner {
        if (!preSaleIQ4Users[userd]) {
            preSaleIQ4Users[userd] = true;
           emit PresaleIQ4WalletStatus(userd);
            }
    
    }

    function isPresaleIQ4Wallet(address userd) private  returns(bool) {
        if (preSaleIQ4Users[userd]) {
                if(block.timestamp <= 1675069200){ // Mon Jan 30 2023 09:00:00 GMT+0000
                    return true;
            }else{
            delete preSaleIQ4Users[userd];  
            return false;              
            }
    }else{
        return false;
    }
    }

    function getPresaleIQ4WalletStatus(address userd) public view returns(bool) {
        return preSaleIQ4Users[userd];
    }

    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) private view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setAsAppAccount(address account) external onlyOwner() {
		App_Fees_Address = account;
    }

	
	function updateFee(uint256 _burnFee,uint256 _appFee) onlyOwner() public{
		require(_burnFee < 100 && _appFee < 100);
        _Burn_Fee = _burnFee * 100;
		_App_Fees = _appFee* 100;
		ORIG_Burn_Fee = _Burn_Fee;
		ORIG_App_Fees = _App_Fees;
	}
	

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Inspirest: approve from the zero address");
        require(spender != address(0), "Inspirest: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Inspirest: transfer from the zero address");
        require(recipient != address(0), "Inspirest: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(isPresaleIQ1Wallet(sender) == false, "PRESALE-I Q1:Transfer lock will be unlocked automatically on April 30, 2022.");
        require(isPresaleIQ2Wallet(sender) == false, "PRESALE-I Q2:Transfer lock will be unlocked automatically on July 30, 2022.");
        require(isPresaleIQ3Wallet(sender) == false, "PRESALE-I Q3:Transfer lock will be unlocked automatically on October 30, 2022.");
        require(isPresaleIQ4Wallet(sender) == false, "PRESALE-I Q4:Transfer lock will be unlocked automatically on January 30, 2023.");
        

        // Remove fees for transfers to and from app account or to excluded account
        bool takeFee = true;
        if (App_Fees_Address == sender || App_Fees_Address == recipient || _isExcluded[recipient]) {
            takeFee = false;
        }

        if (!takeFee) removeAllFee();
        
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tApp) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _standardTransferContent(sender, recipient, rAmount, rTransferAmount);
        _sendToApp(tApp, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tApp);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _standardTransferContent(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tApp) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _excludedFromTransferContent(sender, recipient, tTransferAmount, rAmount, rTransferAmount);        
        _sendToApp(tApp, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tApp);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _excludedFromTransferContent(address sender, address recipient, uint256 tTransferAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);    
    }
    

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tApp) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _excludedToTransferContent(sender, recipient, tAmount, rAmount, rTransferAmount);
        _sendToApp(tApp, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tApp);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _excludedToTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tApp) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _bothTransferContent(sender, recipient, tAmount, rAmount, tTransferAmount, rTransferAmount);  
        _sendToApp(tApp, sender);
        _reflectFee(rFee, rBurn, tFee, tBurn, tApp);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _bothTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn, uint256 tApp) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tAppTotal = _tAppTotal.add(tApp);
        _tTotal = _tTotal.sub(tBurn);
		emit Transfer(address(this), address(0), tBurn);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tBurn, uint256 tApp) = _getTBasics(tAmount, _TAX_FEE, _Burn_Fee, _App_Fees);
        uint256 tTransferAmount = getTTransferAmount(tAmount, tFee, tBurn, tApp);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rFee) = _getRBasics(tAmount, tFee, currentRate);
        uint256 rTransferAmount = _getRTransferAmount(rAmount, rFee, tBurn, tApp, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tApp);
    }
    
    function _getTBasics(uint256 tAmount, uint256 taxFee, uint256 burnFee, uint256 appFee) private view returns (uint256, uint256, uint256) {
        uint256 tFee = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);
        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint256 tApp = ((tAmount.mul(appFee)).div(_GRANULARITY)).div(100);
        return (tFee, tBurn, tApp);
    }
    
    function getTTransferAmount(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tApp) private pure returns (uint256) {
        return tAmount.sub(tFee).sub(tBurn).sub(tApp);
    }
    
    function _getRBasics(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        return (rAmount, rFee);
    }
    
    function _getRTransferAmount(uint256 rAmount, uint256 rFee, uint256 tBurn, uint256 tApp, uint256 currentRate) private pure returns (uint256) {
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rApp = tApp.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rApp);
        return rTransferAmount;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _sendToApp(uint256 tApp, address sender) private {
        uint256 currentRate = _getRate();
        uint256 rApp = tApp.mul(currentRate);
        _rOwned[App_Fees_Address] = _rOwned[App_Fees_Address].add(rApp);
        _tOwned[App_Fees_Address] = _tOwned[App_Fees_Address].add(tApp);
        emit Transfer(sender, App_Fees_Address, tApp);
    }

    function removeAllFee() private {
        if(_Burn_Fee == 0 && _App_Fees == 0) return;
        
        ORIG_Burn_Fee = _Burn_Fee;
        ORIG_App_Fees = _App_Fees;
        
        _Burn_Fee = 0;
        _App_Fees = 0;
    }
    
    function restoreAllFee() private {
        _Burn_Fee = ORIG_Burn_Fee;
        _App_Fees = ORIG_App_Fees;
    }

}