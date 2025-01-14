// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/alphavault/IGMXPositionManager.sol";
import "./interface/stargate/IStargateRouter.sol";
import "./interface/stargate/IStargateLpStaking.sol";
import "./interface/stargate/IStargatePool.sol";
import "./interface/traderjoe/IJoeRouter02.sol";
import "./librairies/ECDSA.sol";

/// @title AlphaVault
/// @author HedgeFarm
/// @notice A vault with simple epoch gestion for the alpha 1 strategy of HedgeFarm.
contract AlphaVault is ERC20, Ownable {
    /// @notice The token that can be deposited or withdrawn.
    address public token;
    /// @notice The signer for the deposits' signatures.
    address public signer;
    /// @notice The vault manager can start, stop and manage positions.
    address public manager;
    /// @notice The address getting the fees.
    address public feeRecipient;
    // @notice The swap router of TraderJoe
    address public swapRouter = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    /// @notice Boolean to indicate if the strategy is running and has allocated funds in a lending protocol.
    bool public isEpochRunning;
    /// @notice The maximum total balance cap for the strategy.
    uint256 public cap;
    /// @notice The current management fee.
    uint8 public managementFee = 0;
    /// @notice The current performance fee.
    uint8 public performanceFee = 0;

    /// @notice When funds are allocated, stores the last relevant price per IOU.
    uint256 public lastPricePerShare;
    /// @notice When funds are allocated, stores the last relevant total balance.
    uint256 public lastTotalBalance;
    /// @notice The moment when the epoch started.
    uint256 public lastEpochStart;

    /// @notice Stargate lending addresses.
    IStargateLpStaking public stargateLpStaking;
    IStargateRouter public stargateRouter = IStargateRouter(0x45A01E4e04F14f7A4a6702c74187c5F6222033cd);
    address public stargateLpToken;
    address public stgToken = address(0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590);
    uint8 public stargateRouterPoolId;
    uint8 public stargateLpStakingPoolId;

    /// @notice AlphaVault helper to open/close positions on GMX.
    address public gmxPositionManager;
    /// @notice Count of long/short positions currently opened.
    uint256 public currentOpenPositions = 0;

    modifier onlyManagerOwner {
        require(msg.sender == owner() || msg.sender == manager, "Unauthorized");
        _;
    }

    /// @notice This event is triggered when a deposit is completed.
    /// @param from The address depositing funds.
    /// @param amount The amount in {token} deposited.
    event Deposit(address indexed from, uint256 amount);

    /// @notice This event is triggered when a withdraw is completed.
    /// @param to The address withdrawing funds.
    /// @param amount The amount in {token} withdrawn.
    event Withdraw(address indexed to, uint256 amount);

    /// @notice This event is triggered when a harvest is completed.
    event Harvest();

    /// @notice This event is triggered when we start an epoch.
    /// @param totalAmount The amount to be allocated in lending and trading.
    event Start(uint256 totalAmount);

    /// @notice This event is triggered when we stop an epoch.
    /// @param totalAmount The amount from the lending, trading and rewards.
    event Stop(uint256 totalAmount);

    /// @notice Creates a new vault with a {token} that can be lent in Stargate.
    /// @param _name The name of the vault token.
    /// @param _symbol The symbol of the vault token.
    /// @param _token The token that can be deposited or withdrawn.
    /// @param _signer The signer for the deposits' signatures.
    /// @param _manager The address that can start/stop/manage positions.
    /// @param _feeRecipient The recipient of the performance and management fees.
    /// @param _cap The maximum total balance cap of the vault.
    /// @param _stargateLpStaking The contract to stake the Stargate LP token.
    /// @param _stargateLpToken The contract of the Stargate LP token.
    /// @param _stargateRouterPoolId The pool ID of the token for the Stargate router.
    /// @param _stargateLpStakingPoolId The pool ID of the token for Stargate staking.
    constructor(
        string memory _name,
        string memory _symbol,
        address _token,
        address _signer,
        address _manager,
        address _feeRecipient,
        uint256 _cap,
        address _stargateLpStaking,
        address _stargateLpToken,
        uint8 _stargateRouterPoolId,
        uint8 _stargateLpStakingPoolId
    ) ERC20(_name, _symbol) {
        token = _token;
        signer = _signer;
        manager = _manager;
        feeRecipient = _feeRecipient;
        cap = _cap;
        stargateLpStaking = IStargateLpStaking(_stargateLpStaking);
        stargateLpToken = _stargateLpToken;
        stargateRouterPoolId = _stargateRouterPoolId;
        stargateLpStakingPoolId = _stargateLpStakingPoolId;
        isEpochRunning = false;
    }

    /// @notice Deposit an amount in the contract.
    /// @param _amount The amount of {want} to deposit.
    /// @param _signature An off-chain generated signature to check the allow list participation of the sender
    function deposit(uint256 _amount, bytes calldata _signature) external {
        require(!isEpochRunning, "Disabled when during epoch");
        require(_amount + totalBalance() <= cap, "Cap reached");

        bytes32 signedMessage = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender)));
        require(ECDSA.recover(signedMessage, _signature) == signer, "Not allowed");

        uint256 pool = totalBalance();
        IERC20(token).transferFrom(msg.sender, address(this), _amount);

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = _amount * totalSupply() / pool;
        }

        _mint(msg.sender, shares);

        emit Deposit(msg.sender, _amount);
    }

    /// @notice Withdraws all the shares of the user.
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    /// @notice Withdraws the amount of {token} represented by the user's shares.
    /// @param _shares The amount of shares to withdraw.
    function withdraw(uint256 _shares) public {
        require(!isEpochRunning, "Disabled when during epoch");
        require(_shares <= balanceOf(msg.sender), "Not enough shares");

        uint256 returnAmount = totalBalance() * _shares / totalSupply();

        _burn(msg.sender, _shares);

        IERC20(token).transfer(msg.sender, returnAmount);

        emit Withdraw(msg.sender, returnAmount);
    }

    /// @notice Starts an epoch and allocates the funds to the lending platform and the trading manager.
    /// It blocks the deposits and withdrawals.
    function start() external onlyManagerOwner {
        require(!isEpochRunning, "Already started");
        require(gmxPositionManager != address(0), "No GMX manager");

        lastTotalBalance = totalBalance();
        lastPricePerShare = pricePerShare();
        // solhint-disable-next-line not-rely-on-time
        lastEpochStart = block.timestamp;

        // Deposit 80% of funds in Stargate
        _stargateDeposit(IERC20(token).balanceOf(address(this)) * 80 / 100);

        // Approve GMX for 20% of funds
        IERC20(token).approve(gmxPositionManager, IERC20(token).balanceOf(address(this)));

        isEpochRunning = true;

        emit Start(lastTotalBalance);
    }

    /// @notice Stops the epoch, withdraws funds from farm, unlocks deposits and withdrawals.
    function stop(uint16 fromChainId) external payable onlyManagerOwner {
        require(isEpochRunning, "Already stopped");
        require(currentOpenPositions == 0, "Close all positions on GMX");

        harvest(false);

        if (isSyncWithdrawalPossible()) {
            _stargateSyncRedeem();
        } else {
            _stargateAsyncRedeem(fromChainId);
        }
    }

    /// @notice Harvests and sells the rewards of the lending farm.
    /// @param autocompound Boolean to indicate if it should auto-compound the rewards.
    function harvest(bool autocompound) public {
        require(isEpochRunning, "No funds in lending");

        // Putting 0 will harvest
        stargateLpStaking.deposit(stargateLpStakingPoolId, 0);

        uint256 stgBalance = IERC20(stgToken).balanceOf(address(this));
        IERC20(stgToken).approve(swapRouter, stgBalance);

        address[] memory path = new address[](3);
        path[0] = stgToken;
        path[1] = IJoeRouter02(swapRouter).WAVAX();
        path[2] = token;
        // solhint-disable-next-line not-rely-on-time
        IJoeRouter02(swapRouter).swapExactTokensForTokens(stgBalance, 0, path, address(this), block.timestamp + 10);

        if (autocompound) {
            _stargateDeposit(IERC20(token).balanceOf(address(this)));
        }

        emit Harvest();
    }

    /// @notice Opens a GMX position for a token.
    /// @param indexToken The address of the token that is longed or shorted.
    /// @param tokenAmount The amount in vault {token} to use as collateral.
    /// @param isLong If we long or if we short.
    function openPosition(address indexToken, uint256 tokenAmount, bool isLong) external payable onlyManagerOwner {
        require(gmxPositionManager != address(0), "No position manager");
        require(isEpochRunning, "Epoch not running");
        require(msg.value == 0.02 ether, "Wrong value");
        require(tokenAmount > 10 * 1e6, "Min amount not met");

        IGMXPositionManager(gmxPositionManager).openPosition{value: msg.value}(indexToken, tokenAmount, isLong);

        currentOpenPositions += 1;
    }

    /// @notice Closes the GMX position for a token.
    /// @param indexToken The address of the token that is longed or shorted.
    /// @param isLong If we long or if we short.
    function closePosition(address indexToken, bool isLong) external payable onlyManagerOwner {
        require(gmxPositionManager != address(0), "No position manager");
        require(isEpochRunning, "Epoch not running");
        require(msg.value == 0.02 ether, "Wrong value");

        IGMXPositionManager(gmxPositionManager).closePosition{value: msg.value}(indexToken, isLong);

        currentOpenPositions -= 1;
    }

    /// @notice Returns the total balance of {token} in strategy. When funds are allocated, it returns the last relevant balance.
    /// @return The total balance amount in {token}.
    function totalBalance() public view returns (uint256) {
        if (isEpochRunning) {
            return lastTotalBalance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /// @notice Returns the price of a single share. When funds are allocated, it returns the last relevant price.
    /// @return The price of a single share.
    function pricePerShare() public view returns (uint256) {
        if (isEpochRunning) {
            return lastPricePerShare;
        } else {
            return totalSupply() == 0 ? 1e18 : totalBalance() * 1e18 / totalSupply();
        }
    }

    /// @notice Deposits and stakes funds in Stargate.
    /// @param amount The amount of {token} to deposit.
    function _stargateDeposit(uint256 amount) internal {
        IERC20(token).approve(address(stargateRouter), amount);
        stargateRouter.addLiquidity(stargateRouterPoolId, amount, address(this));
        uint256 receivedLpToken = IERC20(stargateLpToken).balanceOf(address(this));
        IERC20(stargateLpToken).approve(address(stargateLpStaking), receivedLpToken);
        stargateLpStaking.deposit(stargateLpStakingPoolId, receivedLpToken);
    }

    /// @notice Returns the LP balance staked in Stargate.
    /// @return The LP amount staked.
    function _getStargateLpBalance() internal returns (uint256) {
        (uint256 amount,) = stargateLpStaking.userInfo(stargateLpStakingPoolId, address(this));
        return amount;
    }

    /// @notice Does an instant redeem from Stargate and closes the epoch.
    function _stargateSyncRedeem() internal {
        uint256 totalLpTokens = _getStargateLpBalance();
        stargateLpStaking.withdraw(stargateLpStakingPoolId, totalLpTokens);
        stargateRouter.instantRedeemLocal(stargateRouterPoolId, totalLpTokens, address(this));

        _computeFees();

        isEpochRunning = false;
        emit Stop(IERC20(token).balanceOf(address(this)));
    }

    /// @notice Does an async redeem from Stargate.
    /// @param fromChainId The chain id where the Stargate funds should be coming.
    function _stargateAsyncRedeem(uint16 fromChainId) internal {
        require(msg.value >= 0.3 * 10 ** 18, "RedeemLocal requires funds");

        uint256 totalLpTokens = _getStargateLpBalance();
        stargateLpStaking.withdraw(stargateLpStakingPoolId, totalLpTokens);

        IStargateRouter.lzTxObj memory lzTxObj = IStargateRouter.lzTxObj(0, 0, "0x");
        stargateRouter.redeemLocal{value: 0.3 * 10 ** 18}(
            fromChainId,
            stargateRouterPoolId, // source pool
            stargateRouterPoolId, // destination pool
            payable(address(msg.sender)), // refund extra native gas to this address
            totalLpTokens, // the amount of LP to withdraw
            abi.encodePacked(address(this)), // receiver
            lzTxObj
        );
    }

    /// @notice Admin helper to confirm Stargate async withdraw completed and to close the eopch.
    function confirmStargateAsyncRedeem() external onlyManagerOwner {
        _computeFees();
        isEpochRunning = false;
        emit Stop(IERC20(token).balanceOf(address(this)));
    }

    /// @notice Stargate helper querying delta credits to determine if an instant withdrawal is possible.
    /// @return True if an instant withdrawal is available for our LP count.
    function isSyncWithdrawalPossible() public returns (bool) {
        uint256 deltaCredit = IStargatePool(stargateLpToken).deltaCredit();
        uint256 deltaCreditInLP = _amountSDtoLP(deltaCredit);
        return deltaCreditInLP >= _getStargateLpBalance();
    }

    /// @notice Conversion helper from Stargate.
    /// @param amountSD An amount of liquidity.
    /// @return A LP amount.
    function _amountSDtoLP(uint256 amountSD) internal returns (uint256) {
        require(IStargatePool(stargateLpToken).totalLiquidity() > 0, "No liquidity");
        return amountSD * IStargatePool(stargateLpToken).totalSupply() / IStargatePool(stargateLpToken).totalLiquidity();
    }

    /// @notice Computes the management and the performance fee and executes them.
    function _computeFees() internal {
        // Management fee
        // solhint-disable-next-line not-rely-on-time
        uint256 managementFeeAmount = lastTotalBalance * (block.timestamp - lastEpochStart) / (60 * 60 * 24 * 365) * managementFee / 100;
        _mint(feeRecipient, managementFeeAmount * totalSupply() / lastTotalBalance);

        // Performance fee
        int256 delta = int256(IERC20(token).balanceOf(address(this))) - int256(lastTotalBalance);
        if (delta > 0) {
            uint256 performanceFeeAmount = uint256(delta) * performanceFee / 100;
            IERC20(token).transfer(feeRecipient, performanceFeeAmount);
        }
    }

    /// @notice Updates the maximum total balance cap.
    /// @param _cap The new cap to apply.
    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }

    /// @notice Sets a new GMX position manager.
    /// @param _gmxPositionManager The address of the GMX position manager.
    function setGMXPositionManager(address _gmxPositionManager) external onlyOwner {
        gmxPositionManager = _gmxPositionManager;
    }

    /// @notice Sets a new swap router.
    /// @param _swapRouter The address of the new swap router.
    function setSwapRouter(address _swapRouter) external onlyOwner {
        swapRouter = _swapRouter;
    }

    /// @notice Sets a new manager.
    /// @param _manager The address of the new manager.
    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    /// @notice Sets a fee recipient.
    /// @param _feeRecipient The address of the new fee recipient.
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /// @notice Sets the management and the performance fee.
    /// @param _managementFee The amount (in percent) of management fee.
    /// @param _performanceFee The amount (in percent) of performance fee.
    function setFees(uint8 _managementFee, uint8 _performanceFee) external onlyOwner {
        require(_managementFee <= 2, "Fee too high");
        require(_performanceFee <= 20, "Fee too high");
        managementFee = _managementFee;
        performanceFee = _performanceFee;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGMXPositionManager {
    function openPosition(address indexToken, uint256 tokenAmount, bool isLong) external payable;
    function closePosition(address indexToken, bool isLong) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 poolId, uint256 amount, address to) external;
    function instantRedeemLocal(uint16 poolId, uint256 amountLp, address to) external returns (uint256);
    function redeemLocal(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress, uint256 _amountLP, bytes calldata _to, lzTxObj memory _lzTxParams) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStargateLpStaking {
    function pendingStargate(uint256 pid, address user) external view returns (uint256);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function userInfo(uint256 pid, address user) external returns (uint256, uint256);
    function poolInfo(uint256 poolId) external returns(address,  uint256, uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStargatePool {
    function amountLPtoLD(uint256 _amountLP) external view returns (uint256);
    function deltaCredit() external returns (uint256);
    function totalLiquidity() external returns (uint256);
    function totalSupply() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJoeRouter02 {
    function WAVAX() external pure returns (address);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

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
    function recover(bytes32 hash, bytes memory signature) external pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) external pure returns (bytes32) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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