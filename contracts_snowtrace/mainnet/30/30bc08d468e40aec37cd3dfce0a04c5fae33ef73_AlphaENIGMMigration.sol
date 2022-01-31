/**
 *Submitted for verification at snowtrace.io on 2021-11-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-23
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;

  function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
  address internal _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view override returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual override onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner_)
    public
    virtual
    override
    onlyOwner
  {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner_);
    _owner = newOwner_;
  }
}

interface IERC20 {
  function decimals() external view returns (uint8);

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrrt(uint256 a) internal pure returns (uint256 c) {
    if (a > 3) {
      c = a;
      uint256 b = add(div(a, 2), 1);
      while (b < c) {
        c = b;
        b = div(add(div(a, b), b), 2);
      }
    } else if (a != 0) {
      c = 1;
    }
  }

  /*
   * Expects percentage to be trailed by 00,
   */
  function percentageAmount(uint256 total_, uint8 percentage_)
    internal
    pure
    returns (uint256 percentAmount_)
  {
    return div(mul(total_, percentage_), 1000);
  }

  /*
   * Expects percentage to be trailed by 00,
   */
  function substractPercentage(uint256 total_, uint8 percentageToSub_)
    internal
    pure
    returns (uint256 result_)
  {
    return sub(total_, div(mul(total_, percentageToSub_), 1000));
  }

  function percentageOfTotal(uint256 part_, uint256 total_)
    internal
    pure
    returns (uint256 percent_)
  {
    return div(mul(part_, 100), total_);
  }

  /**
   * Taken from Hypersonic https://github.com/M2629/HyperSonic/blob/main/Math.sol
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function quadraticPricing(uint256 payment_, uint256 multiplier_)
    internal
    pure
    returns (uint256)
  {
    return sqrrt(mul(multiplier_, payment_));
  }

  function bondingCurve(uint256 supply_, uint256 multiplier_)
    internal
    pure
    returns (uint256)
  {
    return mul(multiplier_, supply_);
  }
}

contract AlphaENIGMMigration is Ownable {
  using SafeMath for uint256;

  uint256 swapEndBlock;

  IERC20 public ENIGM;
  IERC20 public aENIGM;

  bool public isInitialized;

  mapping(address => uint256) public senderInfo;

  mapping(address => uint256) public claimed;
  mapping(address => uint256) public lastMigration;

  address[] public whitelistedAddresses;

  uint256[] public steps;
  uint256[] public percentPerStep;

  function initialize(address _ENIGM, address _aENIGM) public onlyOwner {
    ENIGM = IERC20(_ENIGM);
    aENIGM = IERC20(_aENIGM);
    isInitialized = true;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
        return true;
      }
    }
    return false;
  }

  function available(
    uint256 timestamp,
    uint256 balance,
    uint256 lastMigration
  ) public view returns (uint256) {
    if (timestamp < steps[0]) {
      return 0;
    }
    uint256 claimed = 0;
    uint256 claimable = 0;
    for (uint256 i = steps.length; i > 0; i--) {
      uint256 step = steps[i - 1];
      if (lastMigration < step && timestamp >= step) {
        claimable += percentPerStep[i - 1];
      } else if (lastMigration >= step) {
        claimed += percentPerStep[i - 1];
      }
    }
    if (timestamp > steps[steps.length - 1]) {
      return balance;
    }
    uint256 originalBalance = (balance / (100 - claimed)) * 100;
    return (originalBalance * claimable) / 100;
  }

  function check(address _user) public view returns (uint256) {
    return
      available(block.timestamp, aENIGM.balanceOf(_user), lastMigration[_user]);
  }

  function migrate() external {
    uint256 availableTokens = check(msg.sender);
    require(isWhitelisted(msg.sender), "You must claim your tokens using the wallet you were whitelisted with.");
    require(availableTokens > 0, "No available tokens to claim.");
    require(
      aENIGM.allowance(msg.sender, address(this)) >= availableTokens,
      "Base token allowance too low."
    );
    aENIGM.transferFrom(msg.sender, address(this), availableTokens);
    lastMigration[msg.sender] = block.timestamp;
    ENIGM.transfer(msg.sender, availableTokens);
  }

  function withdrawAll() external onlyOwner {
    require(
      block.timestamp > steps[steps.length - 1],
      "Migration of aENIGM has not ended"
    );
    uint256 amount = ENIGM.balanceOf(address(this));
    ENIGM.transfer(msg.sender, amount);
  }

  function setVestingInfos(
    uint256[] calldata _steps,
    uint256[] calldata _percentPerStep
  ) public onlyOwner {
    delete steps;
    delete percentPerStep;
    steps = _steps;
    percentPerStep = _percentPerStep;
  }

  function getSteps() external view returns (uint256[] memory) {
    return steps;
  }

  function getPercentPerSteps() external view returns (uint256[] memory) {
    return percentPerStep;
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
}