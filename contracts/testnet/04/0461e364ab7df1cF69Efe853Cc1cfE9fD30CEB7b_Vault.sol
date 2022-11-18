// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IManager.sol";
import "../interfaces/IJoeOracle.sol";
import "../interfaces/IVaultConfig.sol";
import "../interfaces/IWAVAX.sol";
import "../utils/Math.sol";

// import "hardhat/console.sol";


contract Vault is ERC20, Ownable, ReentrancyGuard, Pausable {
  using SafeERC20 for ERC20;

  /* ========== STATE VARIABLES ========== */

  address public tokenA;
  address public tokenB;
  address public lpToken;
  address public manager;

  // uint256 public lastFeeCollectedTime;

  IJoeOracle public priceOracle;
  IVaultConfig public config;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== STRUCTS ========== */

  struct VaultBalance {
    uint256 tokenAAmt;
    uint256 tokenBAmt;
  }

  /* ========== EVENTS ========== */

  event Deposit(address indexed user, uint256 tokenADeposit, uint256 sharesToUser, bool nativeDeposit);
  event Withdraw(address indexed user, uint256 withdrawAmt, bool nativeWithdraw);
  event Rebalance(uint256 equityBefore, uint256 debtBefore, uint256 equityAfter, uint256 debtAfter);
  event Compound(address vault);

  /* ========== ERRORS ========== */

  error IncorrectNativeAmountDeposit(uint256 depositAmt, uint256 msgValue);
  error InsufficientSharesReceived(uint256 minSharesReceive, uint256 sharesToUser);
  error InsufficientTokenAReceived(address tokenA, uint256 _minTokenAReceive, uint256 _tokenABack);
  error WithdrawValueExceedsEquityChange(uint256 _withdrawValue, uint256 _equityChange);
  error UntrustedPrice();
  error UnsafeRebalance();

  /* ========== MODIFIERS ========== */

  /// Collect management fee before interactions
  // modifier collectMgmtFee() {
  //   _mintFee();
  //   _;
  // }

  /* ========== CONSTRUCTOR ========== */

  constructor (
    string memory _name,
    string memory _symbol,
    address _tokenA,
    address _tokenB,
    address _lpToken,
    IJoeOracle _priceOracle,
    IVaultConfig _config
  ) ERC20(_name, _symbol) {
    tokenA = _tokenA;
    tokenB = _tokenB;
    lpToken = _lpToken;
    priceOracle = _priceOracle;
    config = _config;
  }

  /* ========== VIEW FUNCTIONS ========== */

  function sharesToValue(uint256 _sharesToWithdraw) public view returns (uint256) {
    uint256 _shareSupply = totalSupply() /*+ pendingManagementFee()*/;
    if (_shareSupply == 0) return _sharesToWithdraw;
    return _sharesToWithdraw * getEquityValue() / _shareSupply;
  }

  function valueToShares(uint256 _value) public view returns (uint256) {
    return _valueToShares(_value, getEquityValue());
  }

  function getEquity() public view returns (uint256) {
    (uint256 totalEquityValue) = IManager(manager).equityInfo();
    return totalEquityValue;
  }

  function getAssetValue() public view returns (uint256) {
    (,
     ,
     uint256 _tokenAAsset,
     uint256 _tokenBAsset,

    ) = IManager(manager).assetInfo();
    return _tokenAAsset + _tokenBAsset;
  }

  function getDebtValue() public view returns (uint256) {
    (,, uint256 _tokenADebt, uint256 _tokenBDebt) = IManager(manager).debtInfo();
    return _tokenADebt + _tokenBDebt;
  }

  function getEquityValue() public view returns (uint256) {
    (uint256 totalEquityValue) = IManager(manager).equityInfo();
    return totalEquityValue;
  }

  function getAssetAmt() public view returns (uint256, uint256) {
    (uint256 _tokenAAssetAmt, uint256 _tokenBAssetAmt,,,) = IManager(manager).assetInfo();

    return (_tokenAAssetAmt, _tokenBAssetAmt);
  }

  function getDebtAmt() public view returns (uint256, uint256) {
    (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt,,) = IManager(manager).debtInfo();

    return (_tokenADebtAmt, _tokenBDebtAmt);
  }

  function getSvTokenValue() public view returns (uint256) {
    return getEquityValue() * SAFE_MULTIPLIER / totalSupply();
  }

  function getLeverage() public view returns (uint256) {
    // leverage = asset / equity
    return getAssetValue() * SAFE_MULTIPLIER / getEquityValue();
  }

  // current delta = (current LP avax amount -  current borrowed avax amount included interest)/current LP avax amount
  function getDelta() public view returns (int) {
    (uint256 _tokenAAmt,,,,) = IManager(manager).assetInfo();
    (uint256 _tokenADebtAmt,,,) = IManager(manager).debtInfo();

    return int(_tokenAAmt) - int(_tokenADebtAmt);
  }

  function getDebtRatio() public view returns (uint256) {
    return getDebtValue() * SAFE_MULTIPLIER / getAssetValue();
  }

  function checkRebalance() public view returns (bool) {
    return (getDelta() > config.getUpperDelta() ||
            getDelta() < config.getLowerDelta() ||
            getDebtRatio() > config.getUpperDebtRatio() ||
            getDebtRatio() < config.getLowerDebtRatio()
            ) ? true : false;
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  // assume tokenA non-native deposit only
  /* NOTE : Make it payable when native accepted */
  function deposit(uint256 _depositAmt, uint256 _minSharesReceive, bool _nativeDeposit) external payable nonReentrant {
    IManager(manager).compound();

    _transferTokenToVault(tokenA, _depositAmt, _nativeDeposit);
    ERC20(tokenA).safeTransfer(manager, _depositAmt);

    uint256 _depositValue = priceOracle.getAmountsOut(_depositAmt, tokenA, tokenB, lpToken);
    uint256 _equityValue = getEquityValue();

    uint256 _targetLpValue = (_equityValue + _depositValue)
                             * config.getTargetLeverage()
                             / SAFE_MULTIPLIER;

    uint256 _targetDebtValue = (_equityValue + _depositValue)
                               * (config.getTargetLeverage() - 1e18)
                               / SAFE_MULTIPLIER;

    (uint256 borrowA, uint256 borrowB, uint256 repayA,  uint256 repayB) = _calculate(_targetDebtValue);

    _execute(0, _depositValue, _targetLpValue, borrowA, borrowB, repayA, repayB);

    _checkAndMint(_depositAmt, _minSharesReceive, _equityValue, _nativeDeposit);
  }

  function withdraw(uint256 _sharesAmt, uint256 _minTokenAReceive, bool _nativeWithdraw) external nonReentrant {
    IManager(manager).compound();

    require(_sharesAmt > 0, "Quantity must be > 0");
    if(_sharesAmt > balanceOf(msg.sender)) {
      _sharesAmt = balanceOf(msg.sender);
    }

    uint256 _currentEquity = getEquityValue();

    uint256 _sharesToWithdraw = (SAFE_MULTIPLIER - config.withdrawalFeeBps())
                                * _sharesAmt
                                / SAFE_MULTIPLIER;

    _mint(config.withdrawalFeeTreasury(), _sharesAmt - _sharesToWithdraw);
    uint256 _withdrawValue = sharesToValue(_sharesToWithdraw);

    _burn(msg.sender, _sharesAmt);


    uint256 _targetLpValue = (_currentEquity - _withdrawValue)
                             * config.getTargetLeverage()
                             / SAFE_MULTIPLIER;

    uint256 _targetDebtValue = (_currentEquity - _withdrawValue)
                               * (config.getTargetLeverage() - 1e18)
                               / SAFE_MULTIPLIER;

    (uint256 borrowA,
     uint256 borrowB,
     uint256 repayA,
     uint256 repayB
    ) = _calculate(_targetDebtValue);

    _execute(1, _withdrawValue, _targetLpValue, borrowA, borrowB, repayA, repayB);

    _checkAndTransfer(_minTokenAReceive, _withdrawValue, _currentEquity, _nativeWithdraw);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  function _transferTokenToVault(address _token, uint256 _depositAmt, bool _nativeDeposit) internal {

     if (_nativeDeposit) {
      if (msg.value != _depositAmt) {
        revert IncorrectNativeAmountDeposit(_depositAmt, msg.value);
      }
      IWAVAX(_token).deposit{ value: _depositAmt }();
    } else {
      ERC20(_token).safeTransferFrom(msg.sender, address(this), _depositAmt);
    }
  }

  function _calculate(uint256 _targetDebtValue) internal view returns (uint256,
   uint256, uint256, uint256) {

    (,,uint256 _tokenADebt,
    uint256 _tokenBDebt) = IManager(manager).debtInfo();

    uint256 borrowA = 0;
    uint256 borrowB = 0;
    uint256 repayA = 0;
    uint256 repayB = 0;

    // block scoping for stack too deep;
    {
    uint256 _targetTokenADebt = _targetDebtValue * (config.getTokenADebtRatio()) / SAFE_MULTIPLIER;
    uint256 _targetTokenBDebt = _targetDebtValue * (config.getTokenBDebtRatio()) / SAFE_MULTIPLIER;

    if(_targetTokenADebt > _tokenADebt) {
      borrowA = _targetTokenADebt - _tokenADebt;
    } else {
      repayA = _tokenADebt - _targetTokenADebt;
    }
    if(_targetTokenBDebt > _tokenBDebt) {
      borrowB = _targetTokenBDebt - _tokenBDebt;
    } else {
      repayB = _tokenBDebt - _targetTokenBDebt;
    }
    }

    return (borrowA, borrowB, repayA, repayB);
  }

  function _execute(uint256 _depositOrWithdraw,
    uint256 _value,
    uint256 _targetLpValue,
    uint256 borrowA,
    uint256 borrowB,
    uint256 repayA,
    uint256 repayB
  ) internal {

    uint256 canBorrowValue = _depositOrWithdraw == 0 ? _value * (config.getTargetLeverage() - 1e18) / SAFE_MULTIPLIER : _value;
    uint256 canRepayValue = _depositOrWithdraw == 0 ? _value : _value * (getLeverage()) / SAFE_MULTIPLIER;

    (uint256 _borrowA,
      uint256 _borrowB,
      uint256 _repayA,
      uint256 _repayB
    ) = _moreCalc(canBorrowValue, canRepayValue, borrowA, borrowB,repayA,repayB);

    IManager(manager).work(
      // address(this),
      _targetLpValue,
      _borrowA,
      _borrowB,
      _repayA,
      _repayB
    );
  }

  function _moreCalc(uint256 canBorrowValue,
    uint256 canRepayValue,
    uint256 borrowA,
    uint256 borrowB,
    uint256 repayA,
    uint256 repayB
    ) internal pure returns (uint256, uint256, uint256, uint256) {
        uint256 _borrowA;
        uint256 _borrowB;
        uint256 _repayA;
        uint256 _repayB;

        if (borrowA > 0 && borrowB > 0) {
          _borrowA = borrowA * canBorrowValue / (borrowA + borrowB);
          _borrowB = borrowB * canBorrowValue / (borrowA + borrowB);
        } else if (repayA > 0 && repayB > 0) {
          _repayA = repayA * canRepayValue / (repayA + repayB);
          // check that calculated _repayA does not exceed optimal repayA
          _repayA = (_repayA > repayA) ? repayA : _repayA;
          _repayB = repayB * canRepayValue / (repayA + repayB);
          _repayB = (_repayB > repayB) ? repayB : _repayB;
        } else {
          uint256 borrowRepayRatio = (borrowA + borrowB)
                                     * 1_000_000
                                     / (borrowA + borrowB + repayA + repayB);

          _borrowA = borrowA == 0 ? 0 : borrowRepayRatio * canBorrowValue / 1_000_000;
          _borrowB = borrowB == 0 ? 0 : borrowRepayRatio * canBorrowValue / 1_000_000;
          _repayA = repayA == 0 ? 0 : (1_000_000 - borrowRepayRatio) * canRepayValue / 1_000_000;
          _repayB = repayB == 0 ? 0 : (1_000_000 - borrowRepayRatio) * canRepayValue / 1_000_000;
        }

        return (_borrowA, _borrowB, _repayA ,_repayB);
  }

  function _checkAndMint(uint256 _depositAmt,
    uint256 _minSharesReceive,
    uint256 _equityBefore,
    bool _nativeDeposit
    ) internal {

    // calculate equity change
    uint256 _value = getEquityValue() - _equityBefore;

    // calculate shares to users
    uint256 _sharesToUser = _valueToShares(_value, _equityBefore);

    if (_sharesToUser < _minSharesReceive) {
        revert InsufficientSharesReceived(_minSharesReceive, _sharesToUser);
    }
    _mint(msg.sender, _sharesToUser);

    uint256 _dust = ERC20(tokenA).balanceOf(address(this));
    ERC20(tokenA).safeTransfer(msg.sender, _dust);

    emit Deposit(msg.sender, _depositAmt, _sharesToUser, _nativeDeposit);
  }

  function _checkAndTransfer(
    uint256 _minTokenAReceive,
    uint256 _withdrawValue,
    uint256 _equityBefore,
    bool _nativeWithdraw
    ) internal {

    uint256 _withdrawAmt = ERC20(tokenA).balanceOf(address(this));

    if (_withdrawAmt < _minTokenAReceive) {
      revert InsufficientTokenAReceived(tokenA, _minTokenAReceive, _withdrawAmt);
    }

    uint256 _equityChange = 0;
    if (_equityBefore >= getEquityValue()) {
      _equityChange = _equityBefore - getEquityValue();
    }

    if (_withdrawValue < _equityChange) {
      revert WithdrawValueExceedsEquityChange(_withdrawValue, _equityChange);
    }

    address payable _user = payable(msg.sender);
    if (_nativeWithdraw) {
      IWAVAX(tokenA).withdraw(_withdrawAmt);
      _user.transfer(_withdrawAmt);

      emit Withdraw(msg.sender, _withdrawAmt, _nativeWithdraw);
    } else {
      ERC20(tokenA).safeTransfer(_user, _withdrawAmt);

      emit Withdraw(msg.sender, _withdrawAmt, _nativeWithdraw);
    }

    emit Withdraw(msg.sender, _withdrawAmt, _nativeWithdraw);
  }

  function _valueToShares(uint256 _value, uint256 _currentEquity) internal view returns (uint256) {
    uint256 _sharesSupply = totalSupply() /*+ pendingManagementFee()*/;
    if (_sharesSupply == 0) return _value;
    return _value * _sharesSupply / _currentEquity;
  }

  function _getVaultBalance() internal view returns (VaultBalance memory) {
    return
      VaultBalance({
        tokenAAmt: ERC20(tokenA).balanceOf(address(this)),
        tokenBAmt: ERC20(tokenB).balanceOf(address(this))
      });
  }

  // function _mintFee() public {
  //   _mint(config.managementFeeTreasury(), pendingManagementFee());
  //   lastFeeCollectedTime = block.timestamp;
  // }

  // function pendingManagementFee() public view returns (uint256) {
  //   uint256 _secondsFromLastCollection = block.timestamp - lastFeeCollectedTime;
  //   return (totalSupply() * config.managementFeePerSec() / SAFE_MULTIPLIER * _secondsFromLastCollection) / SAFE_MULTIPLIER;
  // }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function rebalance() external {
    uint256 _equityBefore = getEquityValue();
    uint256 _debtBefore = getDebtValue();

    uint256 _targetLpValue = _equityBefore
                            * config.getTargetLeverage()
                            / SAFE_MULTIPLIER;

    uint256 _targetDebtValue = _equityBefore
                              * (config.getTargetLeverage() - 1e18)
                              / SAFE_MULTIPLIER;

    (uint256 borrowA, uint256 borrowB, uint256 repayA, uint256 repayB) = _calculate(_targetDebtValue);

    IManager(manager).work(
      _targetLpValue,
      borrowA,
      borrowB,
      repayA,
      repayB
    );

    uint256 _equityAfter = getEquityValue();
    uint256 _debtAfter = getDebtValue();

    if(!Math.almostEqual(_equityAfter, _equityBefore, config.getRebalanceToleranceBps())) {
      revert UnsafeRebalance();
    }

    emit Rebalance(_equityBefore, _debtBefore, _equityAfter, _debtAfter);
  }

  function compound() external {
    IManager(manager).compound();

    emit Compound(address(this));
  }

  function updateManager(address _manager) external {
    manager = _manager;
  }

  /* ========== FALLBACK FUNCTIONS ========== */

  /**
    * Fallback function to receive native token sent to this contract,
    * needed for receiving native token to contract when unwrapped
  */
  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IManager {
  function assetInfo() external view returns (uint256, uint256, uint256, uint256, uint256);

  function debtInfo() external view returns (uint256, uint256, uint256, uint256);

  function equityInfo() external view returns (uint256);

  function work(
    uint256 _targetLpValue,
    uint256 _borrowTokenAValue,
    uint256 _borrowTokenBValue,
    uint256 _repayTokenAValue,
    uint256 _repayTokenBValue
  ) external;

  function compound() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IJoeOracle {
  function getAmountsOut(
    uint256 _amountIn,
    address _token0,
    address _token1,
    address _pair
  ) external view returns (uint256);

  function getAmountsIn(
    uint256 _amountOut,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);

  function getLpTokenReserves(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256, uint256, uint256);

  function getLpTokenAmount(
    uint256 _value,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Math {
  function almostEqual(
    uint256 value0,
    uint256 value1,
    uint256 toleranceBps
  ) internal pure returns (bool) {
    uint256 maxValue = max(value0, value1);
    return ((maxValue - min(value0, value1)) * 10000) <= toleranceBps * maxValue;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWAVAX {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVaultConfig {
  // /// @dev Return if the caller is exempted from fee.
  // function feeExemptedCallers(address _caller) external returns (bool);

  /// @dev Return management fee treasury
  function managementFeeTreasury() external view returns (address);

  /// @dev Return management fee per sec.
  function managementFeePerSec() external view returns (uint256);

  /// @dev Get withdrawal fee.
  function withdrawalFeeBps() external returns (uint256);

  /// @dev Return the withdrawl fee treasury.
  function withdrawalFeeTreasury() external view returns (address);

  function getTargetDelta() external view returns (uint256);

  function getUpperDelta() external view returns (int);

  function getLowerDelta() external view returns (int);

  function getTargetLeverage() external view returns (uint256);

  function getTokenADebtRatio() external view returns (uint256);

  function getTokenBDebtRatio() external view returns (uint256);

  function getUpperDebtRatio() external view returns (uint256);

  function getLowerDebtRatio() external view returns (uint256);

  function getRebalanceToleranceBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
interface IERC20Permit {
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