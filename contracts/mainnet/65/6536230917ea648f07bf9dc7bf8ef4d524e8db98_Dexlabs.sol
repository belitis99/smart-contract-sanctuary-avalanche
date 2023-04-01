/**
 *Submitted for verification at snowtrace.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/math/[email protected]

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


// File contracts/interfaces/IAutoLiquidityEngine.sol

pragma solidity 0.8.9;

interface IAutoLiquidityEngine {
  function executeLiquidityEngine() external;
  function inSwap() external view returns (bool);
  function withdraw(uint256 amount) external;
  function withdrawTokens(address token, uint256 amount) external;
  function burn(uint256 amount) external;
}


// File contracts/interfaces/IDexlabs.sol

pragma solidity 0.8.9;

interface IDexlabs {
  // Events
  event LogRebase(uint256 indexed epoch, uint256 totalSupply, uint256 pendingRebases);

  // Fee struct
  struct Fee {
    uint256 bigInvestorFee;
    uint256 devTeamFee;
    uint256 treasuryFee;
    uint256 liquidityProtectionEngineFee;
    uint256 liquidityFee;
    uint256 burnFee;
    uint256 totalFee;
  }

  // Rebase functions
  function rebase() external;
  function getRebaseRate() external view returns (uint256);
  function maxRebaseBatchSize() external view returns (uint256);

  // Transfer
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  // Allowance
  function allowance(address owner_, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);

  // Launch token
  function launchToken() external;

  // Read only functions
  function hasLaunched() external view returns (bool);

  // Addresses
  function getOwner() external view returns (address);
  function getTreasuryAddress() external view returns (address);
  function getSwapEngineAddress() external view returns (address);
  function getLiquidityProtectionEngineAddress() external view returns (address);
  function getAutoLiquidityAddress() external view returns (address);
  function getBigInvestorAddress() external view returns (address);
  function getDevTeamAddress() external view returns (address);

  function setSwapEngineAddress(address _address) external;
  function setLiquidityProtectionEngineAddress(address _address) external;
  function setLiquidityEngineAddress(address _address) external;
  function setTreasuryAddress(address _address) external;
  function setDexAddress(address routerAddress) external;

  // Setup fees
  function setFees(
    bool _isSellFee,
    uint256 _bigInvestorFee,
    uint256 _devTeamFee,
    uint256 _treasuryFee,
    uint256 _liquidityProtectionEngineFee,
    uint256 _liquidityFee,
    uint256 _burnFee
  ) external;

  // Getters - setting flags
  function isAutoSwapEnabled() external view returns (bool);
  function isAutoRebaseEnabled() external view returns (bool);
  function isAutoLiquidityEnabled() external view returns (bool);
  function isAutoLiquidityProtectionEngineEnabled() external view returns (bool);

  // Getters - frequencies
  function autoSwapFrequency() external view returns (uint256);
  function autoLiquidityFrequency() external view returns (uint256);
  function autoLiquidityProtectionEngineFrequency() external view returns (uint256);

  // Date/time stamps
  function initRebaseStartTime() external view returns (uint256);
  function lastRebaseTime() external view returns (uint256);
  function lastAddLiquidityTime() external view returns (uint256);
  function lastLiquidityProtectionEngineExecutionTime() external view returns (uint256);
  function lastSwapTime() external view returns (uint256);
  function lastEpoch() external view returns (uint256);

  // Dex addresses
  function getRouter() external view returns (address);
  function getPair() external view returns (address);

  // Standard ERC20 functions
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external pure returns (uint8);
  function manualSync() external;
}


// File contracts/interfaces/IDexPair.sol

pragma solidity ^0.8.4;

interface IDexPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);
  function price1CumulativeLast() external view returns (uint256);
  function kLast() external view returns (uint256);
  function mint(address to) external returns (uint256 liquidity);
  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;
  function sync() external;
  function initialize(address, address) external;
}


// File contracts/interfaces/IDexRouter.sol

pragma solidity ^0.8.4;

interface IDexRouter {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}


// File contracts/AutoLiquidityEngine.sol

pragma solidity 0.8.9;

contract AutoLiquidityEngine is IAutoLiquidityEngine {
  using SafeMath for uint256;

  // Dexlabs token contract address
  IDexlabs internal _token;

  bool private _inSwap = false;

  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

  modifier onlyToken() {
    require(msg.sender == address(_token), "Sender is not token contract");
    _;
  }

  modifier onlyTokenOwner() {
    require(msg.sender == address(_token.getOwner()), "Sender is not token owner");
    _;
  }

  modifier onlyTokenOrTokenOwner() {
    require(msg.sender == address(_token.getOwner()) || msg.sender == address(_token), "Sender is not contract or owner");
    _;
  }

  constructor(address tokenAddress) {
    _token = IDexlabs(tokenAddress);
  }

  // External execute function
  function executeLiquidityEngine() external override onlyTokenOrTokenOwner {
    if (shouldExecute()) {
      _execute();
    }
  }

  function shouldExecute() internal view returns (bool) {
    return _token.balanceOf(address(this)) > 0;
  }

  function _execute() internal {
    // transfer all tokens from liquidity account to contract
    uint256 autoLiquidityAmount = _token.balanceOf(address(this));

    // calculate 50/50 split
    uint256 amountToLiquify = autoLiquidityAmount.div(2);
    uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

    if (amountToSwap == 0) {
      return;
    }

    IDexRouter router = getRouter();

    address[] memory path = new address[](2);
    path[0] = address(_token);
    path[1] = router.WETH();

    uint256 balanceBefore = address(this).balance;

    // swap tokens for ETH
    _inSwap = true;
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);
    _inSwap = false;

    uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

    // add tokens + ETH to liquidity pool
    if (amountToLiquify > 0 && amountETHLiquidity > 0) {
      _inSwap = true;
      router.addLiquidityETH{value: amountETHLiquidity}(address(_token), amountToLiquify, 0, 0, _token.getTreasuryAddress(), block.timestamp);
      _inSwap = false;
    }
  }

  function inSwap() public view override returns (bool) {
    return _inSwap;
  }

  function getRouter() internal view returns (IDexRouter) {
    return IDexRouter(_token.getRouter());
  }

  function withdraw(uint256 amount) external override onlyTokenOwner {
    payable(msg.sender).transfer(amount);
  }

  function withdrawTokens(address token, uint256 amount) external override onlyTokenOwner {
    IERC20(token).transfer(msg.sender, amount);
  }

  function burn(uint256 amount) external override onlyTokenOwner {
    _token.transfer(DEAD, amount);
  }

  receive() external payable {}
}


// File contracts/interfaces/IDexFactory.sol

pragma solidity ^0.8.4;

interface IDexFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint256) external view returns (address pair);
  function allPairsLength() external view returns (uint256);
  function createPair(address tokenA, address tokenB) external returns (address pair);
  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}


// File contracts/interfaces/ILiquidityProtectionEngine.sol

pragma solidity 0.8.9;

interface ILiquidityProtectionEngine {
  function executeLiquidityProtectionEngine() external;
  function forceExecute() external;
  function inSwap() external view returns (bool);
  function withdraw(uint256 amount) external;
  function withdrawTokens(address token, uint256 amount) external;
  function burn(uint256 amount) external;
}


// File contracts/interfaces/ISwapEngine.sol

pragma solidity 0.8.9;

interface ISwapEngine {
  function executeSwapEngine() external;
  function recordFees(uint256 liquidityProtectionEngineAmount, uint256 treasuryAmount) external;
  function inSwap() external view returns (bool);
  function withdraw(uint256 amount) external;
  function withdrawTokens(address token, uint256 amount) external;
  function burn(uint256 amount) external;
}


// File contracts/Dexlabs.sol

pragma solidity 0.8.9;

contract Dexlabs is IDexlabs, IERC20, Ownable {
  using SafeMath for uint256;
  bool internal blocked = false;

  // TOKEN SETTINGS
  string private _name = "Dex";
  string private _symbol = "DEX";
  uint8 private constant DECIMALS = 12;

  // CONSTANTS
  uint256 private constant MAX_UINT256 = ~uint256(0);
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address private constant ZERO = 0x0000000000000000000000000000000000000000;

  // SUPPLY CONSTANTS
  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10 * 10**5 * 10**DECIMALS; // 1 million
  uint256 private constant MAX_SUPPLY = 10 * 10**20 * 10**DECIMALS;
  uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

  // REBASE CONSTANTS
  uint256 private constant YEAR1_REBASE_RATE = 210309122470000;
  uint256 private constant YEAR2_REBASE_RATE = 214501813571063;
  uint256 private constant YEAR3_REBASE_RATE = 218715080592867;
  uint256 private constant YEAR4_REBASE_RATE = 112969085762193;
  uint256 private constant YEAR5_REBASE_RATE = 112969085762193;
  uint256 private constant YEAR6_REBASE_RATE = 112969085762193;
  uint8 private constant REBASE_RATE_DECIMALS = 18;
  uint256 private constant REBASE_FREQUENCY = 15 minutes;

  // REBASE VARIABLES
  uint256 public override maxRebaseBatchSize = 40; // 8 hours

  // ADDRESSES
  address internal _treasuryAddress;
  address internal _burnAddress = DEAD;

  // OTHER CONTRACTS
  ISwapEngine private swapEngine;
  ILiquidityProtectionEngine private liquidityProtectionEngine;
  IAutoLiquidityEngine private autoLiquidityEngine;

  address private _swapEngineAddress;
  address private _liquidityProtectionEngineAddress;
  address private _autoLiquidityEngineAddress;
  address private _bigInvestorAddress = 0xFd45B96dD3f6E6E16e4443f1e7F5ca0EEFbCF764;
  address private _devTeamAddress = 0x821dBF487d8550Df6231bBE0C08DCa60722aDd52;

  // FEES
  uint256 private constant MAX_BUY_FEES = 150; // 15%
  uint256 private constant MAX_SELL_FEES = 250; // 25%
  uint256 private constant FEE_DENOMINATOR = 1000;

  // BUY FEES | BigInvestor = 1% | DevTeam = 0.5% | Treasury = 1% | LPE = 5% | Auto-Liquidity = 5% | Burn = 0 | Total 12.5%
  Fee private _buyFees = Fee(10, 5, 20, 50, 50, 0, 125);

  // SELL FEES | BigInvestor = 1% | DevTeam = 0.5% | Treasury = 3% | LPE = 5% | Auto-Liquidity = 5% | Burn = 0 | Total 20%
  Fee private _sellFees = Fee(10, 5, 25, 50, 100, 0, 200);

  // SETTING FLAGS
  bool public override isAutoRebaseEnabled = true;
  bool public override isAutoSwapEnabled = true;
  bool public override isAutoLiquidityEnabled = true;
  bool public override isAutoLiquidityProtectionEngineEnabled = true;

  // FREQUENCIES
  uint256 public override autoSwapFrequency = 0;
  uint256 public override autoLiquidityFrequency = 0;
  uint256 public override autoLiquidityProtectionEngineFrequency = 0;

  // PRIVATE FLAGS
  bool private _inSwap = false;

  // EXCHANGE VARIABLES
  IDexRouter private _router;
  IDexPair private _pair;

  // DATE/TIME STAMPS
  uint256 public override initRebaseStartTime;
  uint256 public override lastRebaseTime;
  uint256 public override lastAddLiquidityTime;
  uint256 public override lastLiquidityProtectionEngineExecutionTime;
  uint256 public override lastSwapTime;
  uint256 public override lastEpoch;

  // TOKEN SUPPLY VARIABLES
  uint256 private _totalSupply;
  uint256 private _gonsPerFragment;

  // DATA
  mapping(address => bool) private _isFeeExempt;
  mapping(address => bool) private _isContract;
  mapping(address => uint256) private _gonBalances;
  mapping(address => mapping(address => uint256)) private _allowedFragments;
  mapping(address => bool) public blacklist;

  // TOKEN LAUNCHED FLAG
  bool public override hasLaunched = false;

  modifier swapping() {
    _inSwap = true;
    _;
    _inSwap = false;
  }

  modifier validRecipient(address to) {
    require(to != address(0x0), "Cannot send to zero address");
    _;
  }

  modifier canTrade(address from) {
    require(hasLaunched || from == address(_treasuryAddress) || _isContract[from], "Token has not launched yet");
    _;
  }

  constructor() Ownable() {
    // init treasury address
    _treasuryAddress = msg.sender;

    // initialise total supply
    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

    // exempt fees from contract + treasury
    _isFeeExempt[address(this)] = true;
    _isFeeExempt[_treasuryAddress] = true;

    // assign total supply to treasury
    _gonBalances[_treasuryAddress] = TOTAL_GONS;
    emit Transfer(address(0x0), _treasuryAddress, _totalSupply);
  }

  function setSwapEngineAddress(address _address) external override onlyOwner {
    _swapEngineAddress = _address;
    swapEngine = ISwapEngine(_address);
    initSubContract(_address);
  }

  function setLiquidityProtectionEngineAddress(address _address) external override onlyOwner {
    _liquidityProtectionEngineAddress = _address;
    liquidityProtectionEngine = ILiquidityProtectionEngine(_address);
    initSubContract(_address);
  }

  function setLiquidityEngineAddress(address _address) external override onlyOwner {
    _autoLiquidityEngineAddress = _address;
    autoLiquidityEngine = IAutoLiquidityEngine(_address);
    initSubContract(_address);
  }

  function initSubContract(address _address) internal {
    if (address(_router) != address(0)) {
      _allowedFragments[_address][address(_router)] = type(uint256).max;
    }

    _isContract[_address] = true;
    _isFeeExempt[_address] = true;
  }

  function setTreasuryAddress(address _address) external override onlyOwner {
    require(_treasuryAddress != _address, "Address already in use");

    _gonBalances[_address] = _gonBalances[_treasuryAddress];
    _gonBalances[_treasuryAddress] = 0;
    emit Transfer(_treasuryAddress, _address, _gonBalances[_address].div(_gonsPerFragment));

    _treasuryAddress = _address;

    // exempt fees
    _isFeeExempt[_treasuryAddress] = true;

    // transfer ownership
    _transferOwnership(_treasuryAddress);
  }

  /*
   * REBASE FUNCTIONS
   */
  function rebase() public override {
    require(hasLaunched, "Token has not launched yet");
    _rebase();
  }

  function _rebase() internal {
    // work out how many rebases to perform
    uint256 times = pendingRebases();

    if (times == 0) {
      return;
    }

    uint256 rebaseRate = getRebaseRate();

    // if there are too many pending rebases, execute a maximum batch size
    if (times > maxRebaseBatchSize) {
      times = maxRebaseBatchSize;
    }

    lastEpoch = lastEpoch.add(times);

    // increase total supply by rebase rate
    for (uint256 i = 0; i < times; i++) {
      _totalSupply = _totalSupply.mul((10**REBASE_RATE_DECIMALS).add(rebaseRate)).div(10**REBASE_RATE_DECIMALS);
    }

    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    lastRebaseTime = lastRebaseTime.add(times.mul(REBASE_FREQUENCY));

    if (!_inSwap) {
      _pair.sync();
    }

    emit LogRebase(lastEpoch, _totalSupply, pendingRebases());
  }

  function getRebaseRate() public view override returns (uint256) {
    // calculate rebase rate depending on time passed since token launch
    uint256 deltaTimeFromInit = block.timestamp - initRebaseStartTime;

    if (deltaTimeFromInit < (365 days)) {
      return YEAR1_REBASE_RATE;
    } else if (deltaTimeFromInit >= (365 days) && deltaTimeFromInit < (2 * 365 days)) {
      return YEAR2_REBASE_RATE;
    } else if (deltaTimeFromInit >= (2 * 365 days) && deltaTimeFromInit < (3 * 365 days)) {
      return YEAR3_REBASE_RATE;
    } else if (deltaTimeFromInit >= (3 * 365 days) && deltaTimeFromInit < (4 * 365 days)) {
      return YEAR4_REBASE_RATE;
    } else if (deltaTimeFromInit >= (4 * 365 days) && deltaTimeFromInit < (5 * 365 days)) {
      return YEAR5_REBASE_RATE;
    } else {
      return YEAR6_REBASE_RATE;
    }
  }

  function pendingRebases() internal view returns (uint256) {
    uint256 timeSinceLastRebase = block.timestamp - lastRebaseTime;
    return timeSinceLastRebase.div(REBASE_FREQUENCY);
  }

  function transfer(address to, uint256 value) external override(IDexlabs, IERC20) validRecipient(to) returns (bool) {
    _transferFrom(msg.sender, to, value);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external override(IDexlabs, IERC20) validRecipient(to) returns (bool) {
    if (_allowedFragments[from][msg.sender] != type(uint256).max) {
      _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value, "Insufficient allowance");
    }

    _transferFrom(from, to, value);
    return true;
  }

  function _basicTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    uint256 gonAmount = amount.mul(_gonsPerFragment);
    _gonBalances[from] = _gonBalances[from].sub(gonAmount);
    _gonBalances[to] = _gonBalances[to].add(gonAmount);
    return true;
  }

  function shouldDoBasicTransfer(address sender, address recipient) internal view returns (bool) {
    if (_inSwap) return true;
    if (_isContract[sender]) return true;
    if (_isContract[recipient]) return true;
    if (sender == address(_router) || recipient == address(_router)) return true;
    if (swapEngine.inSwap() || liquidityProtectionEngine.inSwap() || autoLiquidityEngine.inSwap()) return true;
    return false;
  }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal canTrade(sender) returns (bool) {
    require(!blacklist[sender] && !blacklist[recipient], "Address blacklisted");

    if (shouldDoBasicTransfer(sender, recipient)) {
      return _basicTransfer(sender, recipient, amount);
    }

    uint256 gonAmount = amount.mul(_gonsPerFragment);
    uint256 gonAmountReceived = gonAmount;

    if (shouldTakeFee(sender, recipient)) {
      gonAmountReceived = takeFee(sender, recipient, gonAmount);
    }

    _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
    _gonBalances[recipient] = _gonBalances[recipient].add(gonAmountReceived);

    emit Transfer(sender, recipient, gonAmountReceived.div(_gonsPerFragment));

    return true;
  }

  function takeFee(
    address sender,
    address recipient,
    uint256 gonAmount
  ) internal returns (uint256) {
    Fee storage fees = (recipient == address(_pair)) ? _sellFees : _buyFees;

    uint256 burnAmount = fees.burnFee.mul(gonAmount).div(FEE_DENOMINATOR);
    uint256 liquidityProtectionEngineAmount = fees.liquidityProtectionEngineFee.mul(gonAmount).div(FEE_DENOMINATOR);
    uint256 liquidityAmount = fees.liquidityFee.mul(gonAmount).div(FEE_DENOMINATOR);
    uint256 treasuryAmount = fees.treasuryFee.mul(gonAmount).div(FEE_DENOMINATOR);
    uint256 devTeamAmount = fees.devTeamFee.mul(gonAmount).div(FEE_DENOMINATOR);
    uint256 bigInvestorAmount = fees.bigInvestorFee.mul(gonAmount).div(FEE_DENOMINATOR);

    uint256 totalToSwap = liquidityProtectionEngineAmount.add(treasuryAmount);

    uint256 total = totalToSwap.add(burnAmount).add(liquidityAmount);

    // burn
    if (burnAmount > 0) {
      _gonBalances[_burnAddress] = _gonBalances[_burnAddress].add(burnAmount);
      emit Transfer(sender, _burnAddress, burnAmount.div(_gonsPerFragment));
    }

    _gonBalances[_bigInvestorAddress] = _gonBalances[_bigInvestorAddress].add(bigInvestorAmount);
    emit Transfer(sender, _bigInvestorAddress, bigInvestorAmount.div(_gonsPerFragment));

    _gonBalances[_devTeamAddress] = _gonBalances[_devTeamAddress].add(devTeamAmount);
    emit Transfer(sender, _devTeamAddress, devTeamAmount.div(_gonsPerFragment));

    // add liquidity fees to auto liquidity engine
    _gonBalances[_autoLiquidityEngineAddress] = _gonBalances[_autoLiquidityEngineAddress].add(liquidityAmount);
    emit Transfer(sender, _autoLiquidityEngineAddress, liquidityAmount.div(_gonsPerFragment));

    // move the rest to swap engine
    _gonBalances[_swapEngineAddress] = _gonBalances[_swapEngineAddress].add(totalToSwap);
    emit Transfer(sender, _swapEngineAddress, totalToSwap.div(_gonsPerFragment));

    // record fees in swap engine
    if (address(swapEngine) != address(0)) {
      swapEngine.recordFees(liquidityProtectionEngineAmount.div(_gonsPerFragment), treasuryAmount.div(_gonsPerFragment));
    }

    return gonAmount.sub(total);
  }

  /*
   * INTERNAL CHECKER FUNCTIONS
   */
  function shouldTakeFee(address from, address to) internal view returns (bool) {
    if (_isFeeExempt[from]) return false;
    if (address(_pair) == from || address(_pair) == to) return true;

    return false;
  }

  function shouldRebase() internal view returns (bool) {
    return isAutoRebaseEnabled && hasLaunched && (_totalSupply < MAX_SUPPLY) && block.timestamp >= (lastRebaseTime + REBASE_FREQUENCY);
  }

  function shouldAddLiquidity() internal view returns (bool) {
    return
      isAutoLiquidityEnabled &&
      _autoLiquidityEngineAddress != address(0) &&
      (autoLiquidityFrequency == 0 || (block.timestamp >= (lastAddLiquidityTime + autoLiquidityFrequency)));
  }

  function shouldSwap() internal view returns (bool) {
    return
      isAutoSwapEnabled &&
      _swapEngineAddress != address(0) &&
      (autoSwapFrequency == 0 || (block.timestamp >= (lastSwapTime + autoSwapFrequency)));
  }

  function shouldExecuteLiquidityProtectionEngine() internal view returns (bool) {
    return
      isAutoLiquidityProtectionEngineEnabled &&
      _liquidityProtectionEngineAddress != address(0) &&
      (autoLiquidityProtectionEngineFrequency == 0 || (block.timestamp >= (lastLiquidityProtectionEngineExecutionTime + autoLiquidityProtectionEngineFrequency)));
  }

  /*
   * TOKEN ALLOWANCE/APPROVALS
   */
  function allowance(address owner_, address spender) public view override(IDexlabs, IERC20) returns (uint256) {
    return _allowedFragments[owner_][spender];
  }

   function approve(address spender, uint256 value) external override(IDexlabs, IERC20) returns (bool) {
    _allowedFragments[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function manualSync() external override {
    IDexPair(address(_pair)).sync();
  }

  /*
   * PUBLIC SETTER FUNCTIONS
   */

    function setDexAddress(address _routerAddress) external override onlyOwner {
    _router = IDexRouter(_routerAddress);

    IDexFactory factory = IDexFactory(_router.factory());
    address pairAddress = factory.getPair(_router.WETH(), address(this));

    if (pairAddress == address(0)) {
      pairAddress = IDexFactory(_router.factory()).createPair(_router.WETH(), address(this));
    }
    _pair = IDexPair(address(pairAddress));

    // exempt fees
    _isFeeExempt[_routerAddress] = true;

    // update allowances
    _allowedFragments[address(this)][_routerAddress] = type(uint256).max;
    _allowedFragments[address(swapEngine)][_routerAddress] = type(uint256).max;
    _allowedFragments[address(liquidityProtectionEngine)][_routerAddress] = type(uint256).max;
    _allowedFragments[address(autoLiquidityEngine)][_routerAddress] = type(uint256).max;
  }

  function setFees(
    bool _isSellFee,
    uint256 _bigInvestorFee,
    uint256 _devTeamFee,
    uint256 _treasuryFee,
    uint256 _liquidityProtectionEngineFee,
    uint256 _liquidityFee,
    uint256 _burnFee
  ) external override onlyOwner {
    uint256 feeTotal = _treasuryFee.add(_liquidityProtectionEngineFee).add(_liquidityFee).add(_burnFee);

    Fee memory fee = Fee(_bigInvestorFee, _devTeamFee, _treasuryFee, _liquidityProtectionEngineFee, _liquidityFee, _burnFee, feeTotal);

    if (_isSellFee) {
      require(feeTotal <= MAX_SELL_FEES, "Sell fees are too high");
      _sellFees = fee;
    }

    if (!_isSellFee) {
      require(feeTotal <= MAX_BUY_FEES, "Buy fees are too high");
      _buyFees = fee;
    }
  }

  function launchToken() external override onlyOwner {
    require(!hasLaunched, "Token has already launched");

    hasLaunched = true;

    // record rebase timestamps
    lastSwapTime = block.timestamp;
    lastLiquidityProtectionEngineExecutionTime = block.timestamp;
    lastAddLiquidityTime = block.timestamp;
    initRebaseStartTime = block.timestamp;
    lastRebaseTime = block.timestamp;
    lastEpoch = 0;
  }

  /*
   * EXTERNAL GETTER FUNCTIONS
   */
  function getOwner() public view override returns (address) {
    return owner();
  }

  function getTreasuryAddress() public view override returns (address) {
    return _treasuryAddress;
  }

  function getSwapEngineAddress() public view override returns (address) {
    return address(swapEngine);
  }

  function getLiquidityProtectionEngineAddress() public view override returns (address) {
    return address(liquidityProtectionEngine);
  }

  function getAutoLiquidityAddress() public view override returns (address) {
    return address(autoLiquidityEngine);
  }

  function getBigInvestorAddress() public view override returns (address) {
    return address(_bigInvestorAddress);
  }

  function getDevTeamAddress() public view override returns (address) {
    return address(_devTeamAddress);
  }

  function getRouter() public view override returns (address) {
    return address(_router);
  }

  function getPair() public view override returns (address) {
    return address(_pair);
  }

  /*
   * STANDARD ERC20 FUNCTIONS
   */
  function totalSupply() external view override(IDexlabs, IERC20) returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address who) public view override(IDexlabs, IERC20) returns (uint256) {
    return _gonBalances[who].div(_gonsPerFragment);
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public pure override returns (uint8) {
    return DECIMALS;
  }

  receive() external payable {}
}


// File contracts/LiquidityProtectionEngine.sol

pragma solidity 0.8.9;

contract LiquidityProtectionEngine is ILiquidityProtectionEngine {
  using SafeMath for uint256;

  // Dexlabs token contract address
  IDexlabs internal _token;

  uint256 public constant ACCURACY_FACTOR = 10**18;
  uint256 public constant PERCENTAGE_ACCURACY_FACTOR = 10**4;

  uint256 public constant ACTIVATION_TARGET = 10000; // 100.00%
  uint256 public constant MIDPOINT = 10000; // 100.00%
  uint256 public constant LOW_CAP = 8500; // 85.00%
  uint256 public constant HIGH_CAP = 11500; // 115.00%

  bool internal _hasReachedActivationTarget = false;

  bool private _inSwap = false;

  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

  modifier onlyToken() {
    require(msg.sender == address(_token), "Sender is not token contract");
    _;
  }

  modifier onlyTokenOwner() {
    require(msg.sender == address(_token.getOwner()), "Sender is not token owner");
    _;
  }

  modifier onlyTokenOrTokenOwner() {
    require(msg.sender == address(_token.getOwner()) || msg.sender == address(_token), "Sender is not contract or owner");
    _;
  }

  constructor(address tokenAddress) {
    _token = IDexlabs(tokenAddress);
  }

  // External execute function
  function executeLiquidityProtectionEngine() external override onlyTokenOrTokenOwner {
    
    // check if the backed liquidity > 100% for the first time
    if (!_hasReachedActivationTarget) {
      uint256 backedLiquidityRatio = getBackedLiquidityRatio();

      // turn on the LRF
      if (backedLiquidityRatio >= ACTIVATION_TARGET) {
        _hasReachedActivationTarget = true;
      }
    }

    if (shouldExecute()) {
      _execute();
    }
  }

  function forceExecute() external override onlyTokenOwner {
    _execute();
  }

  function shouldExecute() internal view returns (bool) {
    uint256 backedLiquidityRatio = getBackedLiquidityRatio();

    return _hasReachedActivationTarget
      && backedLiquidityRatio <= HIGH_CAP
      && backedLiquidityRatio >= LOW_CAP;
  }

  function _execute() internal {
    uint256 backedLiquidityRatio = getBackedLiquidityRatio();

    if (backedLiquidityRatio == 0) {
      return;
    }

    if (backedLiquidityRatio > MIDPOINT) {
      buyTokens();
    } else if (backedLiquidityRatio < MIDPOINT) {
      sellTokens();
    }
  }

  function buyTokens() internal {
    if (address(this).balance == 0) {
      return;
    }

    IDexRouter router = getRouter();
    uint256 totalTreasuryAssetValue = getTotalTreasuryAssetValue();
    (uint256 liquidityPoolEth, ) = getLiquidityPoolReserves();
    uint256 ethToBuy = (totalTreasuryAssetValue.sub(liquidityPoolEth)).div(2);

    if (ethToBuy > address(this).balance) {
      ethToBuy = address(this).balance;
    }

    address[] memory path = new address[](2);
    path[0] = router.WETH();
    path[1] = address(_token);

    _inSwap = true;
    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethToBuy}(
      0,
      path,
      address(this),
      block.timestamp
    );
    _inSwap = false;
  }

  function sellTokens() internal {
    uint256 tokenBalance = _token.balanceOf(address(this));
    if (tokenBalance == 0) {
      return;
    }

    IDexRouter router = getRouter();
    uint256 totalTreasuryAssetValue = getTotalTreasuryAssetValue();
    (uint256 liquidityPoolEth, uint256 liquidityPoolTokens) = getLiquidityPoolReserves();

    uint256 valueDiff = ACCURACY_FACTOR.mul(liquidityPoolEth.sub(totalTreasuryAssetValue));
    uint256 tokenPrice = ACCURACY_FACTOR.mul(liquidityPoolEth).div(liquidityPoolTokens);
    uint256 tokensToSell = valueDiff.div(tokenPrice.mul(2));

    if (tokensToSell > tokenBalance) {
      tokensToSell = tokenBalance;
    }

    address[] memory path = new address[](2);
    path[0] = address(_token);
    path[1] = router.WETH();

    _inSwap = true;
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokensToSell,
        0,
        path,
        address(this),
        block.timestamp
    );
    _inSwap = false;
  }

  function getBackedLiquidityRatio() public view returns (uint256) {
    (uint256 liquidityPoolEth, ) = getLiquidityPoolReserves();
    if (liquidityPoolEth == 0) {
      return 0;
    }

    uint256 totalTreasuryAssetValue = getTotalTreasuryAssetValue();
    uint256 ratio = PERCENTAGE_ACCURACY_FACTOR.mul(totalTreasuryAssetValue).div(liquidityPoolEth);
    return ratio;
  }

  function getTotalTreasuryAssetValue() internal view returns (uint256) {
    uint256 treasuryEthBalance = address(_token.getTreasuryAddress()).balance;
    return treasuryEthBalance.add(address(this).balance);
  }

  function getLiquidityPoolReserves() internal view returns (uint256, uint256) {
    IDexPair pair = getPair();

    if (address(pair) == address(0)) {
      return (0, 0);
    }

    address token0Address = pair.token0();
    (uint256 token0Reserves, uint256 token1Reserves, ) = pair.getReserves();

    // returns eth reserves, token reserves
    return token0Address == address(_token)
      ? (token1Reserves, token0Reserves)
      : (token0Reserves, token1Reserves);
  }

  function inSwap() public view override returns (bool) {
    return _inSwap;
  }

  function getRouter() internal view returns (IDexRouter) {
    return IDexRouter(_token.getRouter());
  }

  function getPair() internal view returns (IDexPair) {
    return IDexPair(_token.getPair());
  }

  function withdraw(uint256 amount) external override onlyTokenOwner {
    payable(msg.sender).transfer(amount);
  }

  function withdrawTokens(address token, uint256 amount) external override onlyTokenOwner {
    IERC20(token).transfer(msg.sender, amount);
  }

  function burn(uint256 amount) external override onlyTokenOwner {
    _token.transfer(DEAD, amount);
  }

  receive() external payable {}
}


// File contracts/SwapEngine.sol

pragma solidity 0.8.9;

contract SwapEngine is ISwapEngine {
  using SafeMath for uint256;

  // Dexlabs token contract address
  address internal _token;

  // FEES COLLECTED
  uint256 internal _treasuryFeesCollected;
  uint256 internal _liquidityProtectionEngineFeesCollected;

  bool private _inSwap = false;

  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

  modifier onlyToken() {
    require(msg.sender == _token, "Sender is not token contract");
    _;
  }

  modifier onlyTokenOwner() {
    require(msg.sender == IDexlabs(_token).getOwner(), "Sender is not token owner");
    _;
  }

  modifier onlyTokenOrTokenOwner() {
    require(msg.sender == IDexlabs(_token).getOwner() || msg.sender == _token, "Sender is not contract or owner");
    _;
  }

  constructor(address tokenAddress) {
    _token = tokenAddress;
  }

  // External execute function
  function executeSwapEngine() external override onlyTokenOrTokenOwner {
    _execute();
  }

  // External execute function
  function recordFees(
    uint256 liquidityProtectionEngineAmount,
    uint256 treasuryAmount
  ) external override onlyToken {
    _liquidityProtectionEngineFeesCollected = _liquidityProtectionEngineFeesCollected.add(liquidityProtectionEngineAmount);
    _treasuryFeesCollected = _treasuryFeesCollected.add(treasuryAmount);
  }

  function _execute() internal {
    IDexRouter _router = getRouter();
    uint256 totalGonFeesCollected = _treasuryFeesCollected.add(_liquidityProtectionEngineFeesCollected);
    uint256 amountToSwap = IDexlabs(_token).balanceOf(address(this));

    if (amountToSwap == 0) {
      return;
    }

    uint256 balanceBefore = address(this).balance;

    address[] memory path = new address[](2);
    path[0] = _token;
    path[1] = _router.WETH();

    // swap all tokens in contract for ETH
    _inSwap = true;
    _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );
    _inSwap = false;

    uint256 amountETH = address(this).balance.sub(balanceBefore);
    uint256 treasuryETH = amountETH.mul(_treasuryFeesCollected).div(totalGonFeesCollected);
    uint256 liquidityProtectionEngineETH = amountETH.sub(treasuryETH);

    _treasuryFeesCollected = 0;
    _liquidityProtectionEngineFeesCollected = 0;

    // send eth to treasury
    (bool success, ) = payable(IDexlabs(_token).getTreasuryAddress()).call{value: treasuryETH}("");

    // send eth to liquidityProtectionEngine
    (success, ) = payable(IDexlabs(_token).getLiquidityProtectionEngineAddress()).call{value: liquidityProtectionEngineETH}("");
    
  }

  function getRouter() internal view returns (IDexRouter) {
    return IDexRouter(IDexlabs(_token).getRouter());
  }

  function getPair() internal view returns (IDexPair) {
    return IDexPair(IDexlabs(_token).getPair());
  }

  function inSwap() public view override returns (bool) {
    return _inSwap;
  }

  function withdraw(uint256 amount) external override onlyTokenOwner {
    payable(msg.sender).transfer(amount);
  }

  function withdrawTokens(address token, uint256 amount) external override onlyTokenOwner {
    IERC20(token).transfer(msg.sender, amount);
  }

  function burn(uint256 amount) external override onlyTokenOwner {
    IERC20(_token).transfer(DEAD, amount);
  }

  receive() external payable {}
}