// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IFeesRouter.sol";
import "./FeedVault.sol";

contract FeedVaultBaseV3 is FeedVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /// @dev an address of fees router
    address public feesRouter;

    /// @dev Referral Bonus in basis points. Initially set to 70% of 0.1%
    uint256 public referralEntryFeeBP = 5000;
    uint256 public referralExitFeeBP = 5000;

    /// @dev Max referral commission rate: 100% of 0.1%.
    uint16 public constant MAXIMUM_REFERRAL_FEE_BP = 10000;

    /// @dev Total number of users who got referred
    uint256 public totalReferred = 0;

    /// @dev Total number of referrers
    uint256 public totalReferrers = 0;

    /// @dev Referral Mapping
    mapping(address => address) public referrers; // account_address -> referrer_address
    mapping(address => uint256) public referredCount; // referrer_address -> num_of_referred
    mapping(address => mapping(address => uint256)) public referrerRewards; // referrer_address -> token address -> amount
    mapping(address => bool) public referrerExistence; // referrer_address -> boolean
    mapping(address => bool) public firstDeposit; // account_address -> boolean

    /// @dev Events
    event Referral(address indexed _referrer, address indexed _user);
    event ReferralPaid(address indexed _user, address indexed _userTo, uint256 _reward);
    event ReferralEntryFeeBpChanged(uint256 _oldBp, uint256 _newBp);
    event ReferralExitFeeBpChanged(uint256 _oldBp, uint256 _newBp);

    /**
     * @dev Constructor
     */
    constructor(
        IERC20 _token,
        address payable _entryFeesCollector,
        address payable _exitFeesCollector,
        address _swapRouterAddress,
        address[] memory _entryFeesToTokenPath,
        address[] memory _exitFeesToTokenPath,
        address _feesRouter
    ) {
        token = IERC20(_token);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);

        entryFeesCollector = _entryFeesCollector;
        exitFeesCollector = _exitFeesCollector;
        swapRouterAddress = _swapRouterAddress;
        entryFeesToTokenPath = _entryFeesToTokenPath;
        exitFeesToTokenPath = _exitFeesToTokenPath;
        feesRouter = _feesRouter;
    }

    function deposit(uint256 _amount) public override isEnabled hasVaults nonReentrant {}

    /**
     * @dev Deposit Fund to FeedVault
     */
    function depositReferrer(uint256 _amount, address _referrer) external virtual isEnabled hasVaults nonReentrant {
        // Collect Target Vaults Profit Shares
        uint256 length = vaultInfo.length;
        for (uint256 i = 0; i < length; i++) {
            if (vaultInfo[i].enabled && ITargetVault(vaultInfo[i].targetVault).balanceOfToken() > 0)
                ITargetVault(vaultInfo[i].targetVault).collectFees();
        }

        uint256 _beforeDepositBalance = depositedTokenBalance(false);

        // Transfer Token from Depositor to Vault
        token.safeTransferFrom(address(msg.sender), address(this), _amount);

        // Collect Entry Fees
        _setReferrer(msg.sender, _referrer);
        _collectEntryFees(_amount);

        // Allocate to vaults in order to get new vaults balance
        _allocate();

        // Get Pool Balance after deposited
        uint256 _afterDepositBalance = depositedTokenBalance(false);

        // Additional check for deflationary tokens
        uint256 _balance = 0;
        if (_afterDepositBalance >= _beforeDepositBalance) {
            _balance = _afterDepositBalance.sub(_beforeDepositBalance);
        }

        if (_balance > 0) {
            uint256 shares = 0;
            if (totalShares == 0) {
                shares = _balance;
            } else {
                shares = (_balance.mul(totalShares)).div(_beforeDepositBalance);
            }
            UserInfo storage user = userInfo[address(msg.sender)];
            totalShares = totalShares.add(shares);
            user.shares = user.shares.add(shares);
            user.depositedAt = block.number;
        }

        emit Deposited(address(msg.sender), _balance);
    }

    /**
     * @dev Discount fees based on fees strategy
     */
    function _discountFees(uint256 _amount) internal returns (uint256) {
        uint256 _feesAfterDiscount = _amount;

        // If fees controller is set, adjust lender and borrower fees accordingly
        if (feesRouter != address(0)) {
            // Calculate and set lender & borrower fee by using discount basis point from FeesController
            _feesAfterDiscount = _amount.sub(_amount.mul(IFeesRouter(feesRouter).getDiscountBP(address(msg.sender))).div(10000));
        }

        return _feesAfterDiscount;
    }

    /**
     * @dev Collect Entry Fees
     */
    function _collectEntryFees(uint256 _amount) internal override {
        // Collect Entry Fees
        uint256 _entryFees = _amount.mul(entryFeesBP).div(10000);

        // Fees discount
        _entryFees = _discountFees(_entryFees);
        if (_entryFees > 0) {
            if (autoSwapEntryFees) {
                address _entrySwapToken = entryFeesToTokenPath[entryFeesToTokenPath.length - 1];
                uint256 buyBackBefore = IERC20(_entrySwapToken).balanceOf(address(this));
                _safeSwap(swapRouterAddress, _entryFees, entryFeesToTokenPath, address(this), block.timestamp + 120);
                uint256 buyBackAfter = IERC20(_entrySwapToken).balanceOf(address(this));
                uint256 buyBackAmount = buyBackAfter.sub(buyBackBefore);

                uint256 _comissionPaid =
                    _payReferralCommission(address(msg.sender), address(_entrySwapToken), buyBackAmount, referralEntryFeeBP);
                uint256 _remainingFees = buyBackAmount.sub(_comissionPaid);

                IERC20(_entrySwapToken).safeTransfer(entryFeesCollector, _remainingFees);

                emit FeesCollected(true, address(entryFeesCollector), address(_entrySwapToken), _remainingFees);
            } else {
                uint256 _comissionPaid = _payReferralCommission(address(msg.sender), address(token), _entryFees, referralEntryFeeBP);
                uint256 _remainingFees = _entryFees.sub(_comissionPaid);

                IERC20(token).safeTransfer(entryFeesCollector, _remainingFees);

                emit FeesCollected(true, address(entryFeesCollector), address(token), _remainingFees);
            }
        }
    }

    /**
     * @dev Collect Exit Fees
     */
    function _collectExitFees(uint256 _amount) internal override returns (uint256) {
        uint256 _tokenAmount = _amount;
        uint256 _exitFees = _tokenAmount.mul(exitFeesBP).div(10000);

        // Fees discount
        _exitFees = _discountFees(_exitFees);
        if (_exitFees > 0) {
            if (autoSwapExitFees) {
                address _exitSwapToken = exitFeesToTokenPath[exitFeesToTokenPath.length - 1];
                uint256 buyBackBefore = IERC20(_exitSwapToken).balanceOf(address(this));
                _safeSwap(swapRouterAddress, _exitFees, exitFeesToTokenPath, address(this), block.timestamp + 120);
                uint256 buyBackAfter = IERC20(_exitSwapToken).balanceOf(address(this));
                uint256 buyBackAmount = buyBackAfter.sub(buyBackBefore);

                uint256 _comissionPaid =
                    _payReferralCommission(address(msg.sender), address(_exitSwapToken), buyBackAmount, referralExitFeeBP);
                uint256 _remainingFees = buyBackAmount.sub(_comissionPaid);

                IERC20(_exitSwapToken).safeTransfer(exitFeesCollector, _remainingFees);

                emit FeesCollected(false, address(exitFeesCollector), address(_exitSwapToken), _remainingFees);
            } else {
                uint256 _comissionPaid = _payReferralCommission(address(msg.sender), address(token), _exitFees, referralExitFeeBP);
                uint256 _remainingFees = _exitFees.sub(_comissionPaid);

                IERC20(token).safeTransfer(exitFeesCollector, _remainingFees);

                emit FeesCollected(false, address(exitFeesCollector), address(token), _remainingFees);
            }
            _tokenAmount = _tokenAmount.sub(_exitFees);
        }

        return _tokenAmount;
    }

    /**
     * @dev [Deprecated] Set entry swap token address
     */
    function setEntrySwapToken(address _entrySwapToken) public override onlyRole(ADMIN_ROLE) nonReentrant {}

    /**
     * @dev [Deprecated] Set exit swap token address
     */
    function setExitSwapToken(address _exitSwapToken) public override onlyRole(ADMIN_ROLE) nonReentrant {}

    /**
     * @dev Set entry fees to token path
     */
    function setEntryFeesToTokenPath(address[] memory _entryFeesToTokenPath) external virtual onlyRole(ADMIN_ROLE) nonReentrant {
        entryFeesToTokenPath = _entryFeesToTokenPath;
    }

    /**
     * @dev Set exit fees to token path
     */
    function setExitFeesToTokenPath(address[] memory _exitFeesToTokenPath) external virtual onlyRole(ADMIN_ROLE) nonReentrant {
        exitFeesToTokenPath = _exitFeesToTokenPath;
    }

    /**
     * @dev Set fees router address
     */
    function setFeesRouter(address _feesRouter) external virtual onlyRole(ADMIN_ROLE) nonReentrant {
        feesRouter = _feesRouter;
    }

    /**
     * @dev Pay Referral Comissions
     */
    function _payReferralCommission(
        address _user,
        address _token,
        uint256 _fee,
        uint256 _feeBP
    ) internal returns (uint256) {
        uint256 _referralFeeAmt = 0;
        address _referrer = referrers[_user];
        if (_referrer != address(0) && _referrer != _user && _feeBP > 0) {
            _referralFeeAmt = _fee.mul(_feeBP).div(10000);
            referrerRewards[_referrer][address(_token)] += _referralFeeAmt;
            IERC20(_token).transfer(_referrer, _referralFeeAmt);

            emit ReferralPaid(_user, _referrer, _referralFeeAmt);
        }

        return _referralFeeAmt;
    }

    /**
     * @dev Set Referral for User
     */
    function _setReferrer(address _user, address _referrer) internal {
        if (
            _referrer == address(_referrer) &&
            referrers[_user] == address(0) &&
            _referrer != address(0) &&
            _referrer != _user &&
            !firstDeposit[_user]
        ) {
            referrers[_user] = _referrer;
            referredCount[_referrer] += 1;

            totalReferred += 1;

            if (!referrerExistence[_referrer]) {
                referrerExistence[_referrer] = true;
                totalReferrers += 1;
            }

            emit Referral(_user, _referrer);
        }
        firstDeposit[_user] = true;
    }

    /**
     * @dev Set Referral Fee Basis Point
     */
    function setReferralEntryFeeBp(uint256 _referralEntryFeeBP) public onlyRole(ADMIN_ROLE) {
        require(_referralEntryFeeBP <= MAXIMUM_REFERRAL_FEE_BP, "LIMIT");
        uint256 oldReferralEntryFeeBP = referralEntryFeeBP;
        referralEntryFeeBP = _referralEntryFeeBP;

        emit ReferralEntryFeeBpChanged(oldReferralEntryFeeBP, referralEntryFeeBP);
    }

    /**
     * @dev Set Referral Fee Basis Point
     */
    function setReferralExitFeeBp(uint256 _referralExitFeeBP) public onlyRole(ADMIN_ROLE) {
        require(_referralExitFeeBP <= MAXIMUM_REFERRAL_FEE_BP, "LIMIT");
        uint256 oldReferralExitFeeBP = referralExitFeeBP;
        referralExitFeeBP = _referralExitFeeBP;

        emit ReferralExitFeeBpChanged(oldReferralExitFeeBP, referralExitFeeBP);
    }

    /**
     * @dev Safe swap token with slippage
     */
    function _safeSwap(
        address _routerAddress,
        uint256 _amountIn,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal virtual {
        IERC20 _token = IERC20(_path[0]);
        _token.safeApprove(_routerAddress, 0);
        _token.safeIncreaseAllowance(_routerAddress, _amountIn);
        uint256[] memory amounts = IPancakeRouter02(_routerAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IPancakeRouter02(_routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            _deadline
        );
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
pragma solidity >=0.7.0 <0.9.0;

interface IFeesRouter {
    function getDiscountBP(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/targetVaults/ITargetVault.sol";
import "../interfaces/IPancakeRouter02.sol";

abstract contract FeedVault is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /**
     * @dev Token accepted by Vault
     */
    IERC20 public token;

    /**
     * @dev Array for Vaults
     */
    struct VaultInfo {
        bool enabled;
        address targetVault;
        uint256 allocPoint;
    }
    VaultInfo[] public vaultInfo;

    /**
     * @dev Array for Users
     */
    struct UserInfo {
        uint256 shares;
        uint256 depositedAt;
    }

    /**
     * @dev Total Shares issued
     */
    uint256 public totalShares;

    /**
     * @dev Total allocation points. Must be the sum of all allocation points in all pools.
     */
    uint256 public totalAllocPoint = 0;

    /**
     * @dev Wrapped BNB
     */
    address public constant wBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /**
     * @dev Swap token address
     */
    address public entrySwapToken = 0x67d66e8Ec1Fd25d98B3Ccd3B19B7dc4b4b7fC493;
    address public exitSwapToken = 0x67d66e8Ec1Fd25d98B3Ccd3B19B7dc4b4b7fC493;

    /**
     * @dev Fees basis points
     */
    uint256 public entryFeesBP = 10;
    uint256 public exitFeesBP = 10;

    /**
     * @dev Maximum Fees Basis points
     */
    uint256 public constant MAXIMUM_ENTRY_FEES_BP = 50;
    uint256 public constant MAXIMUM_EXIT_FEES_BP = 50;

    /**
     * @dev Auto Swap Fees options
     */
    bool public autoSwapEntryFees = true;
    bool public autoSwapExitFees = true;

    /**
     * @dev Auto Swap Fees Token and Path
     */
    address[] public entryFeesToTokenPath;
    address[] public exitFeesToTokenPath;

    /**
     * @dev FeesCollector addresses
     */
    address public entryFeesCollector;
    address public exitFeesCollector;

    /**
     * @dev Slippage factor default at 5% tolerance
     */
    uint256 public slippageFactor = 950;

    /**
     * @dev Maximum slippage factor */
    uint256 public constant slippageFactorMax = 995;

    /**
     * @dev Swap Router Address
     */
    address public swapRouterAddress;

    /**
     * @dev Boolean, that if true, disables the target vault
     */
    bool private _vaultDisabled = false;

    /**
     * @dev Mapping, list of users
     */
    mapping(address => UserInfo) public userInfo;

    /**
     * @dev Mapping, list of vaults
     */
    mapping(address => bool) public vaultExistence;

    /**
     * @dev Mapping, target vault ID by address
     */
    mapping(address => uint256) public vaultIdForTargetVaultAddress;

    /**
     * @dev Emitted when vault is enabled
     */
    event VaultEnabled();

    /**
     * @dev Emitted when vault is disabled
     */
    event VaultDisabled();

    /**
     * @dev Emitted when fees collected
     */
    event FeesCollected(bool isEntryFees, address indexed feesCollector, address indexed token, uint256 _amount);

    /**
     * @dev Emitted when entry fees basis points changed
     */
    event EntryFeesBPChanged(uint256 _feesBP);

    /**
     * @dev Emitted when exit fees basis points changed
     */
    event ExitFeesBPChanged(uint256 _feesBP);

    /**
     * @dev Emitted when fees collector address changed
     */
    event EntryFeesCollectorChanged(address _feesCollector);
    event ExitFeesCollectorChanged(address _feesCollector);

    /**
     * @dev Emitted when entry and exit swap token address changed
     */
    event EntrySwapTokenChanged(address _entrySwapToken);
    event ExitSwapTokenChanged(address _exitSwapToken);

    /**
     * @dev Emitted when swap router address changed
     */
    event SwapRouterChanged(address _router);

    /**
     * @dev Emitted when auto swap settings for entry or exit fees changed
     */
    event AutoSwapEntryFees(bool _status);
    event AutoSwapExitFees(bool _status);

    /**
     * @dev Emitted when user deposited to vault
     */
    event Deposited(address indexed from, uint256 _amount);

    /**
     * @dev Emitted when withdraw from vault
     */
    event Withdrawed(address indexed to, uint256 _amount);

    /**
     * @dev Emitted when slippage factor changed
     */
    event SlippageFactorChanged(uint256 _slippageFactor);

    /**
     * @dev Throws if vault is disabled
     */
    modifier isEnabled() {
        require(!_vaultDisabled, "FeedVault: vault is disabled");
        _;
    }

    /**
     * @dev Throws if caller does not has role
     */
    modifier onlyRole(bytes32 _role) {
        require(hasRole(_role, msg.sender), "FeedVault: Caller has no role");
        _;
    }

    /**
     * @dev Thorws if has no vault
     */
    modifier hasVaults() {
        require(vaultInfo.length > 0, "FeedVault: No target vault");
        _;
    }

    /**
     * @dev Throws if duplicated target vault
     */
    modifier nonDuplicated(address _targetVault) {
        require(!vaultExistence[_targetVault], "FeedVault: Duplicated vault");
        _;
    }

    /**
     * @dev Throws if vault does not exists
     */
    modifier vaultExistsById(uint256 _vid) {
        require(_vid < vaultInfo.length, "FeedVault: Vault does not exists");
        _;
    }

    /**
     * @dev Enable vault for upgrade or security purposes
     */
    function enableVault() public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_vaultDisabled, "FeedVault(enableVault): Vault is already enabled");
        _vaultDisabled = false;

        emit VaultEnabled();
    }

    /**
     * @dev Disable vault for upgrade or security purposes
     */
    function disableVault() public onlyRole(ADMIN_ROLE) nonReentrant {
        require(!_vaultDisabled, "FeedVault(disableVault): Vault is already disabled");
        _vaultDisabled = true;

        emit VaultDisabled();
    }

    /**
     * @dev Balance of token in FeedVault
     */
    function availableTokenBalance() public view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Balance of token in TargetVaults
     */
    function depositedBalance() public view virtual returns (uint256) {
        uint256 length = vaultInfo.length;
        uint256 _balance = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 _balanceOf =
                ITargetVault(vaultInfo[i].targetVault).vaultBalance().mul(vaultInfo[i].allocPoint).div(totalAllocPoint);
            _balance = _balance.add(_balanceOf);
        }
        return _balance;
    }

    /**
     * @dev Balance of token in TargetVaults
     */
    function depositedTokenBalance(bool _cachedPrice) public view virtual returns (uint256) {
        uint256 length = vaultInfo.length;
        uint256 _balance = 0;
        for (uint256 i = 0; i < length; i++) {
            if (vaultInfo[i].enabled) {
                uint256 _balanceOfToken = 0;
                if (!_cachedPrice) {
                    _balanceOfToken = ITargetVault(vaultInfo[i].targetVault).balanceOfToken();
                } else {
                    _balanceOfToken = ITargetVault(vaultInfo[i].targetVault)
                        .vaultBalance()
                        .mul(ITargetVault(vaultInfo[i].targetVault).cachedPricePerShare())
                        .div(1e18);
                }
                _balance = _balance.add(_balanceOfToken);
            }
        }
        return _balance;
    }

    /**
     * @dev Total balance of token in FeedVault and TargetVaults combined
     */
    function tokenBalance() public view virtual returns (uint256) {
        return availableTokenBalance().add(depositedTokenBalance(false));
    }

    /**
     * @dev Add target vault
     */
    function addTargetVault(address _targetVault, uint256 _allocPoint)
        public
        virtual
        onlyRole(ADMIN_ROLE)
        nonDuplicated(_targetVault)
        nonReentrant
    {
        require(_targetVault != address(0), "FeedVault(addTargetVault): Target vault cannot be zero address");
        require(
            address(ITargetVault(_targetVault).token()) == address(token),
            "FeedVault(addTargetVault): Target vault token is not the same"
        );
        require(
            ITargetVault(_targetVault).vaultToken() == address(token),
            "FeedVault(addTargetVault): Target vault strategy token is not the same"
        );
        require(
            ITargetVault(_targetVault).feedVault() == address(this),
            "FeedVault(addTargetVault): Target vault feed vault target is not this vault"
        );
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        vaultExistence[_targetVault] = true;
        vaultInfo.push(VaultInfo({enabled: true, targetVault: _targetVault, allocPoint: _allocPoint}));
        vaultIdForTargetVaultAddress[_targetVault] = vaultInfo.length - 1;
    }

    /**
     * @dev Update target vault
     */
    function setTargetVault(uint256 _vid, uint256 _allocPoint) public onlyRole(MANAGER_ROLE) {
        totalAllocPoint = totalAllocPoint.sub(vaultInfo[_vid].allocPoint).add(_allocPoint);
        vaultInfo[_vid].allocPoint = _allocPoint;
    }

    /**
     * @dev Toggle enable status of target vault
     */
    function toggleTargetVault(uint256 _vid, bool _status) public onlyRole(ADMIN_ROLE) nonReentrant {
        vaultInfo[_vid].enabled = _status;
    }

    /**
     * @dev Update multiple target vaults alloc point
     */
    function setAllocPoints(uint256[] memory _allocPoints) public onlyRole(MANAGER_ROLE) nonReentrant {
        require(_allocPoints.length == vaultInfo.length, "FeedVault(setAllocPoints): number of vaults is incorrect");
        uint256 length = vaultInfo.length;
        for (uint256 i = 0; i < length; i++) {
            setTargetVault(i, _allocPoints[i]);
        }
    }

    /**
     * @dev Deposit Fund to FeedVault
     */
    function deposit(uint256 _amount) public virtual isEnabled hasVaults nonReentrant {
        // Collect Target Vaults Profit Shares
        uint256 length = vaultInfo.length;
        for (uint256 i = 0; i < length; i++) {
            if (vaultInfo[i].enabled && ITargetVault(vaultInfo[i].targetVault).balanceOfToken() > 0)
                ITargetVault(vaultInfo[i].targetVault).collectFees();
        }

        uint256 _beforeDepositBalance = depositedTokenBalance(false);

        // Transfer Token from Depositor to Vault
        token.safeTransferFrom(address(msg.sender), address(this), _amount);

        // Collect Entry Fees
        _collectEntryFees(_amount);

        // Allocate to vaults in order to get new vaults balance
        _allocate();

        // Get Pool Balance after deposited
        uint256 _afterDepositBalance = depositedTokenBalance(false);

        // Additional check for deflationary tokens
        uint256 _balance = 0;
        if (_afterDepositBalance >= _beforeDepositBalance) {
            _balance = _afterDepositBalance.sub(_beforeDepositBalance);
        }

        if (_balance > 0) {
            uint256 shares = 0;
            if (totalShares == 0) {
                shares = _balance;
            } else {
                shares = (_balance.mul(totalShares)).div(_beforeDepositBalance);
            }
            UserInfo storage user = userInfo[address(msg.sender)];
            totalShares = totalShares.add(shares);
            user.shares = user.shares.add(shares);
            user.depositedAt = block.number;
        }

        emit Deposited(address(msg.sender), _balance);
    }

    /**
     * @dev Collect Entry Fees
     */
    function _collectEntryFees(uint256 _amount) internal virtual {
        // Collect Entry Fees
        uint256 _entryFees = _amount.mul(entryFeesBP).div(10000);
        if (_entryFees > 0) {
            if (autoSwapEntryFees) {
                uint256 buyBackBefore = IERC20(entrySwapToken).balanceOf(address(this));
                uint256[] memory amounts = IPancakeRouter02(swapRouterAddress).getAmountsOut(_entryFees, entryFeesToTokenPath);
                uint256 amountOut = amounts[amounts.length.sub(1)];
                IERC20(token).safeIncreaseAllowance(swapRouterAddress, _entryFees);
                IPancakeRouter02(swapRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _entryFees,
                    amountOut.mul(slippageFactor).div(1000),
                    entryFeesToTokenPath,
                    address(this),
                    block.timestamp + 120
                );
                uint256 buyBackAfter = IERC20(entrySwapToken).balanceOf(address(this));
                uint256 buyBackAmount = buyBackAfter.sub(buyBackBefore);
                IERC20(entrySwapToken).safeTransfer(entryFeesCollector, buyBackAmount);

                emit FeesCollected(true, address(entryFeesCollector), address(entrySwapToken), _entryFees);
            } else {
                IERC20(token).safeTransfer(entryFeesCollector, _entryFees);

                emit FeesCollected(true, address(entryFeesCollector), address(token), _entryFees);
            }
        }
    }

    /**
     * @dev Deposit all sender's fund to FeedVault
     */
    function depositAll() public virtual isEnabled hasVaults {
        deposit(token.balanceOf(msg.sender));
    }

    /**
     * @dev Withdraw fund from FeedVault
     */
    function withdraw(uint256 _shares) public virtual isEnabled hasVaults nonReentrant {
        UserInfo storage user = userInfo[address(msg.sender)];
        require(user.depositedAt != block.number, "FeedVault(withdraw): withdraw cannot be the same block as deposit");

        // Collect Target Vaults Profit Shares
        uint256 length = vaultInfo.length;
        for (uint256 i = 0; i < length; i++) {
            if (vaultInfo[i].enabled && ITargetVault(vaultInfo[i].targetVault).balanceOfToken() > 0)
                ITargetVault(vaultInfo[i].targetVault).collectFees();
        }
        uint256 _tokenInShares = tokenBalance().mul(_shares).div(totalShares);
        uint256 _tokenInVault = token.balanceOf(address(this));
        totalShares = totalShares.sub(_shares);
        user.shares = user.shares.sub(_shares);

        uint256 _tokenAmount = 0;

        if (_tokenInVault >= _tokenInShares) {
            _tokenAmount = _tokenInShares;
        } else {
            uint256 length = vaultInfo.length;
            uint256 remaining = _tokenInShares.sub(_tokenInVault);
            uint256 depositedToken = depositedTokenBalance(false);
            for (uint256 i = 0; i < length; i++) {
                if (vaultInfo[i].enabled) {
                    uint256 _before = token.balanceOf(address(this));
                    uint256 _withdrawVaultAmount =
                        (ITargetVault(vaultInfo[i].targetVault).balanceOf()).mul(remaining).div(depositedToken);
                    _withdrawFromVault(i, _withdrawVaultAmount);
                    uint256 _after = token.balanceOf(address(this));
                    _tokenAmount = _tokenAmount.add(_after.sub(_before));
                }
            }
            _tokenAmount += _tokenInVault;

            if (_tokenAmount > _tokenInShares) {
                _tokenAmount = _tokenInShares;
            }
        }

        // Collect Exit Fees
        _tokenAmount = _collectExitFees(_tokenAmount);

        token.safeTransfer(msg.sender, _tokenAmount);

        emit Withdrawed(address(msg.sender), _tokenAmount);
    }

    /**
     * @dev Collect Exit Fees
     */
    function _collectExitFees(uint256 _amount) internal virtual returns (uint256) {
        uint256 _tokenAmount = _amount;
        uint256 _exitFees = _tokenAmount.mul(exitFeesBP).div(10000);
        if (_exitFees > 0) {
            if (autoSwapExitFees) {
                uint256 buyBackBefore = IERC20(exitSwapToken).balanceOf(address(this));
                uint256[] memory amounts = IPancakeRouter02(swapRouterAddress).getAmountsOut(_exitFees, exitFeesToTokenPath);
                uint256 amountOut = amounts[amounts.length.sub(1)];
                IERC20(token).safeIncreaseAllowance(swapRouterAddress, _exitFees);
                IPancakeRouter02(swapRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _exitFees,
                    amountOut.mul(slippageFactor).div(1000),
                    exitFeesToTokenPath,
                    address(this),
                    block.timestamp + 120
                );
                uint256 buyBackAfter = IERC20(exitSwapToken).balanceOf(address(this));
                uint256 buyBackAmount = buyBackAfter.sub(buyBackBefore);
                IERC20(exitSwapToken).safeTransfer(exitFeesCollector, buyBackAmount);

                emit FeesCollected(false, address(exitFeesCollector), address(exitSwapToken), _exitFees);
            } else {
                IERC20(token).safeTransfer(exitFeesCollector, _exitFees);

                emit FeesCollected(false, address(exitFeesCollector), address(token), _exitFees);
            }
            _tokenAmount = _tokenAmount.sub(_exitFees);
        }

        return _tokenAmount;
    }

    /**
     * @dev Deposit from FeedVault to TargetVault
     */
    function _depositToVault(uint256 _vid, uint256 _amount) internal virtual {
        uint256 _balance = IERC20(token).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _balance;
        }
        if (_amount > 0) {
            token.safeTransfer(vaultInfo[_vid].targetVault, _amount);
            ITargetVault(vaultInfo[_vid].targetVault).deposit();
        }
    }

    /**
     * @dev Deposit from FeedVault to TargetVault by Manager
     */
    function depositToVault(uint256 _vid, uint256 _amount) public virtual vaultExistsById(_vid) onlyRole(MANAGER_ROLE) nonReentrant {
        _depositToVault(_vid, _amount);
    }

    /**
     * @dev Withdraw from TargetVault to FeedVault
     */
    function _withdrawFromVault(uint256 _vid, uint256 _amount) internal virtual {
        ITargetVault(vaultInfo[_vid].targetVault).withdraw(_amount);
    }

    /**
     * @dev Withdraw from TargetVault to FeedVault by Manager
     */
    function withdrawFromVault(uint256 _vid, uint256 _amount)
        public
        virtual
        vaultExistsById(_vid)
        onlyRole(MANAGER_ROLE)
        nonReentrant
    {
        if (_amount > 0) {
            _withdrawFromVault(_vid, _amount);
        }
    }

    /**
     * @dev Allocate balance to all TargetVaults
     */
    function _allocate() internal virtual isEnabled {
        // Get available balance in vault
        uint256 _balance = availableTokenBalance();

        if (_balance > 0) {
            uint256 length = vaultInfo.length;
            for (uint256 i = 0; i < length; i++) {
                if (vaultInfo[i].enabled) {
                    uint256 _amount = _balance.mul(vaultInfo[i].allocPoint).div(totalAllocPoint);
                    _depositToVault(i, _amount);
                }
            }
        }
    }

    /**
     * @dev Allocate balance to all TargetVaults by Manager
     */
    function allocate() public virtual onlyRole(MANAGER_ROLE) nonReentrant {
        _allocate();
    }

    /**
     * @dev Get vault length
     */
    function vaultLength() public view returns (uint256) {
        return vaultInfo.length;
    }

    /**
     * @dev Get Vault ID by Token
     */
    function getTargetVaultIdForStrategy(address _targetVault) external view returns (uint256) {
        require(vaultExistence[_targetVault], "FeedVault: Token does not exists in any vault");
        return vaultIdForTargetVaultAddress[_targetVault];
    }

    /**
     * @dev Reallocate based on allocation point
     */
    function reallocate() public onlyRole(MANAGER_ROLE) isEnabled hasVaults nonReentrant {
        uint256 _balance = depositedTokenBalance(false);
        uint256 length = vaultInfo.length;
        for (uint256 i = 0; i < length; i++) {
            if (vaultInfo[i].enabled) {
                uint256 _tvBalance = ITargetVault(vaultInfo[i].targetVault).balanceOfToken();
                uint256 _expectedBalance = _balance.mul(vaultInfo[i].allocPoint).div(totalAllocPoint);
                uint256 _amount = 0;
                if (_tvBalance > _expectedBalance) {
                    if (vaultInfo[i].allocPoint == 0) {
                        _amount = ITargetVault(vaultInfo[i].targetVault).balanceOf();
                    } else {
                        _amount = _tvBalance.sub(_expectedBalance).mul(1e18).div(
                            ITargetVault(vaultInfo[i].targetVault).targetPricePerShare()
                        );
                    }
                    _withdrawFromVault(i, _amount);
                }
            }
        }

        uint256 _totalBalance = tokenBalance();
        for (uint256 i = 0; i < length; i++) {
            if (vaultInfo[i].enabled) {
                uint256 _tvBalance = ITargetVault(vaultInfo[i].targetVault).balanceOfToken();
                uint256 _expectedBalance = _totalBalance.mul(vaultInfo[i].allocPoint).div(totalAllocPoint);
                if (_tvBalance < _expectedBalance) {
                    uint256 _diffBalance = _expectedBalance.sub(_tvBalance);
                    if (availableTokenBalance() < _diffBalance) {
                        _depositToVault(i, availableTokenBalance());
                    } else {
                        _depositToVault(i, _diffBalance);
                    }
                }
            }
        }
    }

    /**
     * @dev Set entry fees collector address
     */
    function setEntryFeesCollector(address _feesCollector) public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_feesCollector != address(0), "TargetVault(setEntryFeesCollector): entry fees collector cannot be zero address");

        entryFeesCollector = _feesCollector;

        emit EntryFeesCollectorChanged(entryFeesCollector);
    }

    /**
     * @dev Set exit fees collector address
     */
    function setExitFeesCollector(address _feesCollector) public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_feesCollector != address(0), "TargetVault(setExitFeesCollector): exit fees collector cannot be zero address");

        exitFeesCollector = _feesCollector;

        emit ExitFeesCollectorChanged(exitFeesCollector);
    }

    /**
     * @dev Set entry fees basis points
     */
    function setEntryFeesBP(uint256 _feesBP) public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_feesBP <= MAXIMUM_ENTRY_FEES_BP, "TargetVault(setFees): entry fees basis points exceeds threshold");

        entryFeesBP = _feesBP;

        emit EntryFeesBPChanged(entryFeesBP);
    }

    /**
     * @dev Set exit fees basis points
     */
    function setExitFeesBP(uint256 _feesBP) public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_feesBP <= MAXIMUM_EXIT_FEES_BP, "FeedVault(setFees): entry fees basis points exceeds threshold");

        exitFeesBP = _feesBP;

        emit ExitFeesBPChanged(exitFeesBP);
    }

    /**
     * @dev Set swap router address
     */
    function setSwapRouterAddress(address _router) public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_router != address(0), "FeedVault(setSwapRouterAddress): swap router cannot be zero address");

        swapRouterAddress = _router;

        emit SwapRouterChanged(swapRouterAddress);
    }

    /**
     * @dev Set entry swap token address
     */
    function setEntrySwapToken(address _entrySwapToken) public virtual onlyRole(ADMIN_ROLE) nonReentrant {
        require(_entrySwapToken != address(0), "FeedVault(setEntrySwapToken): entry swap token cannot be zero address");

        entrySwapToken = _entrySwapToken;

        entryFeesToTokenPath = [address(token), wBNB, entrySwapToken];

        emit EntrySwapTokenChanged(entrySwapToken);
    }

    /**
     * @dev Set exit swap token address
     */
    function setExitSwapToken(address _exitSwapToken) public virtual onlyRole(ADMIN_ROLE) nonReentrant {
        require(_exitSwapToken != address(0), "FeedVault(setExitSwapToken): entry swap token cannot be zero address");

        exitSwapToken = _exitSwapToken;

        exitFeesToTokenPath = [address(token), wBNB, exitSwapToken];

        emit ExitSwapTokenChanged(exitSwapToken);
    }

    /**
     * @dev Set auto buy back entry fees on and off
     */
    function setEntryAutoSwap(bool _status) public onlyRole(ADMIN_ROLE) nonReentrant {
        autoSwapEntryFees = _status;

        emit AutoSwapEntryFees(autoSwapEntryFees);
    }

    /**
     * @dev Set auto buy back exit fees on and off
     */
    function setExitAutoSwap(bool _status) public onlyRole(ADMIN_ROLE) nonReentrant {
        autoSwapExitFees = _status;

        emit AutoSwapExitFees(autoSwapExitFees);
    }

    /**
     * @dev Set slippage factor
     */
    function setSlippageFactor(uint256 _slippageFactor) public onlyRole(ADMIN_ROLE) nonReentrant {
        require(_slippageFactor <= slippageFactorMax, "TargetVault(setSlippageFactor): slippageFactor too high");
        slippageFactor = _slippageFactor;

        emit SlippageFactorChanged(slippageFactor);
    }
}

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
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
pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITargetVault {
    function token() external view returns (IERC20);

    function feedVault() external view returns (address);

    function vaultToken() external view returns (address);

    function cachedPricePerShare() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function availableBalance() external view returns (uint256);

    function targetPricePerShare() external view returns (uint256);

    function balanceOfToken() external view returns (uint256);

    function vaultBalance() external view returns (uint256);

    function deposit() external;

    function withdraw(uint256 _amount) external;

    function collectFees() external;

    function retireTargetVault() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IPancakeRouter01 {
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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
}