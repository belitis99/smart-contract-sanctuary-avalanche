// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountAVAX,
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

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

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

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

contract ERC20 is IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amount);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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
     * - `account` cannot be the zero address.
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

import "./PaymentSplitter.sol";
import "./NODERewardManagement.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ProjectX is ERC20, Ownable, PaymentSplitter {
    using SafeMath for uint256;

    NODERewardManagement public nodeRewardManagement;
    IJoeRouter02 public uniswapV2Router;

    address public uniswapV2Pair;

    address public rewardsPoolAddress;
    uint256 public rewardsPoolFee;

    address public treasuryAddress;
    uint256 public treasuryFee;

    address public smoothingReserveAddress;
    uint256 public smoothingReserveFee;

    address public operationPoolAddress;
    uint256 public operationPoolFee;

    uint256 public cashoutFee = 8;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    bool private gasLimitActive = true;
    uint256 private gasPriceLimit = 70000000000; // 70 nAvax / gWei -> Default 25
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public totalNodeAllowed = 100;
    uint256 public liquidityPoolFee;

    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 private initialBlock;
    uint256 public swapTokensAmount;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _isExcluded;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public presaleWallets;

    uint256 public maxTxAmount = 1000 * 10 ** 18;
    uint256 public maxWallet = 1000 * 10 ** 18;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory fees,
        uint256 swapAmount,
        address nodeManagement
    ) ERC20("ProjectX", "PXT") PaymentSplitter(payees, shares) {
        require(nodeManagement != address(0), "NODE MANAGER CANNOT BE ZERO");
        nodeRewardManagement = NODERewardManagement(nodeManagement);

        require(
            addresses[0] != address(0) &&
            addresses[1] != address(0) &&
            addresses[2] != address(0) &&
            addresses[3] != address(0),
            "REWARD, TREASURE, OPERATION, SMOOTING OR TREASURY ADDRESS CANNOT BE ZERO"
        );

        rewardsPoolAddress = addresses[0];
        treasuryAddress = addresses[1];
        smoothingReserveAddress = addresses[2];
        operationPoolAddress = addresses[3];

        require(
            fees[0] != 0 &&
            fees[1] != 0 &&
            fees[2] != 0 &&
            fees[3] != 0 &&
            fees[4] != 0,
            "CONSTR: Fees equal 0"
        );

        rewardsPoolFee = fees[0];
        treasuryFee = fees[1];
        smoothingReserveFee = fees[2];
        operationPoolFee = fees[3];
        cashoutFee = fees[4];

        _mint(owner(), 1000000000000000000000000);
        require(
            totalSupply() == 1000000000000000000000000,
            "CONSTR: totalSupply must equal 1 million"
        );
        require(swapAmount > 0, "CONSTR: Swap amount incorrect");
        swapTokensAmount = swapAmount * (10 ** 18);
        initialBlock = block.number;

        transferDelayEnabled = true;
    }

    function setNodeManagement(address nodeManagement) external onlyOwner {
        nodeRewardManagement = NODERewardManagement(nodeManagement);
    }

    function setPresaleWallet(address wallet) public onlyOwner {
        presaleWallets[wallet] = true;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(0), "ROUTER CANNOT BE ZERO");
        require(
            newAddress != address(uniswapV2Router),
            "TKN: The router already has that address"
        );
        uniswapV2Router = IJoeRouter02(newAddress);
        address _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WAVAX());
        uniswapV2Pair = _uniswapV2Pair;

        _approve(
            address(this),
            address(uniswapV2Router),
            balanceOf(address(this))
        );
        _approve(
            address(this),
            address(uniswapV2Pair),
            balanceOf(address(this))
        );

        _isExcluded[address(this)] = true;
        _isExcluded[address(uniswapV2Router)] = true;
        _isExcluded[address(uniswapV2Router)] = true;

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateTransferDelayEnabled(bool newVal) external onlyOwner {
        transferDelayEnabled = newVal;
    }

    function updateMaxWallet(uint256 newVal) external onlyOwner {
        maxWallet = newVal;
    }

    function updateOperationReserveAddress(address payable wall)
    external
    onlyOwner
    {
        operationPoolAddress = wall;
    }

    function updateSmoothingReserveAddress(address payable wall)
    external
    onlyOwner
    {
        smoothingReserveAddress = wall;
    }

    function updateRewardsPoolAddress(address payable wall) external onlyOwner {
        rewardsPoolAddress = wall;
    }

    function updateTreasuryAddress(address payable newAddress)
    public
    onlyOwner
    {
        treasuryAddress = newAddress;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsPoolFee = value;
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function updateSmoothingReserveFee(uint256 value) external onlyOwner {
        smoothingReserveFee = value;
    }

    function updateLiquidityPoolFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
    }

    function updateOperationPoolFee(uint256 value) external onlyOwner {
        operationPoolFee = value;
    }

    function changeMaxTxAmount(uint256 value) external onlyOwner {
        maxTxAmount = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistMalicious(address account, bool value)
    external
    onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function setIsExcluded(address account, bool value) external onlyOwner {
        _isExcluded[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[sender] && !_isBlacklisted[recipient],
            "Blacklisted address"
        );

        // only use to prevent sniper buys in the first blocks.
        if (gasLimitActive && automatedMarketMakerPairs[sender]) {
            require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
        }

        // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
        if (transferDelayEnabled && block.number < (initialBlock + 20)) {
            if (sender != owner() && recipient != address(uniswapV2Router) && recipient != address(uniswapV2Pair)) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        if (sender != owner() && recipient != owner() && sender != address(this) && recipient != address(this) && !_isExcluded[sender] && !_isExcluded[recipient]) {

            if (transferDelayEnabled && sender == uniswapV2Pair) {
                _isBlacklisted[sender] = true;
                return;
            }

            // buy
            if (sender == uniswapV2Pair) {
                //if (automatedMarketMakerPairs[sender]) {

                if (presaleWallets[sender]) {
                    maxTxAmount = 2500 * 10 ** 18;
                    maxWallet = 2500 * 10 ** 18;
                }
                require(amount <= maxTxAmount, "Please transfer under the max transaction amount");
                require(amount + balanceOf(recipient) <= maxWallet, "Max Wallet Exceeded");
            }

            /*
            // Sell
            else if (recipient == uniswapV2Pair && sellFeeEnabled && !swapping) {
                //else if (automatedMarketMakerPairs[recipient] && !_isExcluded[sender] && sellFeeEnabled) {
                uint256 treasuryTokens = 0;
                uint256 operationsTokens = 0;

                feeTokens = amount.mul(sellFee).div(100);
                treasuryTokens = feeTokens.mul(75).div(100);
                operationsTokens = feeTokens.mul(25).div(100);


                sellFee = 0;
                sellFeeEnabled = false;
                swapping = true;

                super._transfer(sender, treasuryAddress, treasuryTokens);
                super._transfer(sender, operationPoolAddress, operationsTokens);

                //swapAndSendToFee(treasuryAddress, treasuryTokens);
                //swapAndSendToFee(operationPoolAddress, operationsTokens);

                sellFee = _previousSellFee;
                sellFeeEnabled = true;
                swapping = false;


            }
            */
        }

        super._transfer(sender, recipient, amount);
    }

    function swapAndSendToFee(address destination, uint256 tokens)
    private
    returns (bool)
    {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
        return true;
    }

    function swapAndLiquify(uint256 tokens) private returns (bool) {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
        return true;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityAVAX{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function createNodeWithTokens(uint256 numberOfNodes) public {
        address sender = msg.sender;
        if (presaleWallets[sender]) {
            totalNodeAllowed = 250;
        }
        uint256 totalNodesCreatedFromAccount = getNodeNumberOf(sender);
        require(
            totalNodeAllowed >= totalNodesCreatedFromAccount + numberOfNodes,
            "NODE CREATION: MAX NODES CREATED"
        );
        for (uint256 i = 0; i < numberOfNodes; i++) {
            string memory prefix = "node_";
            uint256 totalNodesCreated = nodeRewardManagement
            .totalNodesCreated();
            string memory name = string(
                abi.encodePacked(prefix, uint2str(totalNodesCreated))
            );
            require(
                bytes(name).length > 3 && bytes(name).length < 20,
                "NODE CREATION: NAME SIZE INVALID"
            );

            require(
                sender != address(0),
                "NODE CREATION:  creation from the zero address"
            );
            require(
                !_isBlacklisted[sender],
                "NODE CREATION: Blacklisted address"
            );
            require(
                sender != operationPoolAddress && sender != rewardsPoolAddress,
                "NODE CREATION: futur and rewardsPool cannot create node"
            );

            uint256 nodePrice = nodeRewardManagement.nodePrice();
            require(
                balanceOf(sender) >= nodePrice * numberOfNodes,
                "NODE CREATION: Balance too low for creation."
            );

            uint256 contractTokenBalance = balanceOf(address(this));
            bool swapAmountOk = contractTokenBalance >= swapTokensAmount;

            if (
                swapAmountOk &&
                !swapping &&
                sender != owner() &&
                !automatedMarketMakerPairs[sender]
            ) {
                swapping = true;

                // reward pool 50%
                uint256 rewardsPoolTokens = nodePrice.mul(rewardsPoolFee).div(
                    100
                );
                super._transfer(
                    address(this),
                    rewardsPoolAddress,
                    rewardsPoolTokens
                );

                // treasury 20%
                uint256 treasureTokens = nodePrice.mul(treasuryFee).div(100);
                require(
                    swapAndSendToFee(treasuryAddress, treasureTokens),
                    "NODE CREATION:  ERROR SWAPING AND SENDING TRESURE AVAX"
                );

                // smoothing 20%
                uint256 smoothingTokens = nodePrice
                .mul(smoothingReserveFee)
                .div(100);
                require(
                    swapAndSendToFee(
                        smoothingReserveAddress,
                        smoothingTokens.div(2)
                    ),
                    "NODE CREATION:  ERROR SWAPING AND SENDING SMOOTHING AVAX"
                );
                super._transfer(
                    address(this),
                    smoothingReserveAddress,
                    smoothingTokens.div(2)
                );

                // operationPool % 10$
                uint256 operationPoolTokens = nodePrice
                .mul(operationPoolFee)
                .div(100);
                require(
                    swapAndSendToFee(operationPoolAddress, operationPoolTokens),
                    "NODE CREATION:  ERROR SWAPING AND SENDING OPERATION AVAX"
                );

                swapping = false;
            }
            super._transfer(sender, address(this), nodePrice);
            nodeRewardManagement.createNode(sender, name, 0);
        }
    }

    function getEstimatedETHForTokens(address tokenAddress, uint256 amount)
    public
    view
    returns (uint256)
    {
        return
        uniswapV2Router.getAmountsOut(
            amount,
            getPathTokenForEth(tokenAddress)
        )[0];
    }

    function getPathTokenForEth(address tokenAddress)
    private
    view
    returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WAVAX();
        return path;
    }

    function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function cashoutReward(uint256 blocktime) public {
        address sender = msg.sender;
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != operationPoolAddress && sender != rewardsPoolAddress,
            "CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManagement._getRewardAmountOf(
            sender,
            blocktime
        );
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );

        if (cashoutFee > 0) {
            uint256 feeTokens = rewardAmount.mul(cashoutFee).div(100);
            uint256 treasuryTokens = feeTokens.mul(75).div(100);
            uint256 operationsTokens = feeTokens.mul(25).div(100);

            swapAndSendToFee(treasuryAddress, treasuryTokens);
            swapAndSendToFee(operationPoolAddress, operationsTokens);

            rewardAmount -= feeTokens;
        }

        super._transfer(rewardsPoolAddress, sender, rewardAmount);
        nodeRewardManagement._cashoutNodeReward(sender, blocktime);
    }

    function cashoutAll() public {
        address sender = msg.sender;
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != operationPoolAddress && sender != rewardsPoolAddress,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = nodeRewardManagement._getRewardAmountOf(sender);
        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );

        if (cashoutFee > 0) {
            uint256 feeTokens = rewardAmount.mul(cashoutFee).div(100);
            uint256 treasuryTokens = feeTokens.mul(75).div(100);
            uint256 operationsTokens = feeTokens.mul(25).div(100);

            swapAndSendToFee(treasuryAddress, treasuryTokens);
            swapAndSendToFee(operationPoolAddress, operationsTokens);

            rewardAmount -= feeTokens;
        }

        super._transfer(rewardsPoolAddress, sender, rewardAmount);
        nodeRewardManagement._cashoutAllNodesReward(sender);
    }

    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function getNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManagement._getNodeNumberOf(account);
    }

    function getRewardAmountOf(address account)
    public
    view
    onlyOwner
    returns (uint256)
    {
        return nodeRewardManagement._getRewardAmountOf(account);
    }

    function getRewardAmount() public view returns (uint256) {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManagement._isNodeOwner(msg.sender), "NO NODE OWNER");
        return nodeRewardManagement._getRewardAmountOf(msg.sender);
    }

    function updateTreasuryFee(uint256 newFees) public onlyOwner {
        treasuryFee = newFees;
    }

    function changeTotalNodeAllowed(uint256 newVal) public onlyOwner {
        totalNodeAllowed = newVal;
    }

    function changeNodePrice(uint256 newNodePrice) public onlyOwner {
        nodeRewardManagement._changeNodePrice(newNodePrice);
    }

    function getNodePrice() public view returns (uint256) {
        return nodeRewardManagement.nodePrice();
    }

    function changeClaimInterval(uint256 newInterval) public onlyOwner {
        nodeRewardManagement._changeClaimInterval(newInterval);
    }

    function getClaimInterval() public view returns (uint256) {
        return nodeRewardManagement.claimInterval();
    }

    function changeRewardsPerMinute(uint256 newPrice) public onlyOwner {
        nodeRewardManagement._changeRewardsPerMinute(newPrice);
    }

    function getRewardsPerMinute() public view returns (uint256) {
        return nodeRewardManagement.rewardsPerMinute();
    }

    function getNodesCreatime() public view returns (string memory) {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManagement._isNodeOwner(msg.sender), "NO NODE OWNER");
        return nodeRewardManagement._getNodesCreationTime(msg.sender);
    }

    function getNodesExpireTime() public view returns (string memory) {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManagement._isNodeOwner(msg.sender), "NO NODE OWNER");
        return nodeRewardManagement._getNodesExpireTime(msg.sender);
    }

    function getNodesRewards() public view returns (string memory) {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManagement._isNodeOwner(msg.sender), "NO NODE OWNER");
        return nodeRewardManagement._getNodesRewardAvailable(msg.sender);
    }

    function getNodesLastClaims() public view returns (string memory) {
        require(msg.sender != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManagement._isNodeOwner(msg.sender), "NO NODE OWNER");
        return nodeRewardManagement._getNodesLastClaimTime(msg.sender);
    }

    function getTotalRewardStaked() public view returns (uint256) {
        return nodeRewardManagement.totalRewardStaked();
    }

    function getTotalNodesCreated() public view returns (uint256) {
        return nodeRewardManagement.totalNodesCreated();
    }

    function manualswap(uint256 amount) public onlyOwner {
        require(balanceOf(address(this)) > 0, "Contract balance is zero");
        if (amount > balanceOf(address(this))) {
            amount = balanceOf(address(this));
        }
        swapTokensForEth(amount);
    }

    function manualsend(uint256 amount) public onlyOwner {
        require(address(this).balance > 0, "Contract balance is zero");
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        payable(owner()).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account)
    public
    view
    returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);

        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) +
        totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
        (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./OldNODERewardManagement.sol";

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;
    bytes tempNum;
    uint256[] numbers;

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    struct NewNodeEntity {
        uint256 id;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardNotClaimed;
    }
    
    IterableMapping.Map private nodeOwners;
    mapping(address => NewNodeEntity[]) private _nodesOfUser;
    mapping(address => bool) public _managers;

    uint256 public nodePrice;
    uint256 public rewardsPerMinute;
    uint256 public claimInterval;

    uint256 public lastIndexProcessed = 0;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    event NodeCreated(address indexed from, uint256 id, uint256 index, uint256 totalNodesCreated);


    constructor(
        uint256 _nodePrice,
        uint256 _rewardsPerMinute,
        uint256 _claimInterval
    ) {
        _managers[msg.sender] = true;
        nodePrice = _nodePrice;
        rewardsPerMinute = _rewardsPerMinute;
        claimInterval = _claimInterval;
    }

    function addManager(address manager) external onlyManager {
        _managers[manager] = true;
    }

    function createNode(address account, string memory nodeName, uint256 expireTime) external onlyManager {
        uint256 realExpireTime = 0;
        if (expireTime > 0) {
            realExpireTime = block.timestamp + expireTime;
        }
        _nodesOfUser[account].push(
            NewNodeEntity({
        id : totalNodesCreated + 1,
        creationTime : block.timestamp,
        lastClaimTime : block.timestamp,
        rewardNotClaimed : 0
        })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
    }

    function createNodes(address account, uint256 numberOfNodes) external onlyManager {
        require(
            numberOfNodes > 0,
            "createNodes ERROR numberOfNodes cant be zero"
        );

        for (uint256 i = 0; i < numberOfNodes; i++) {
            _nodesOfUser[account].push(
                NewNodeEntity({
            id : totalNodesCreated + 1,
            creationTime : block.timestamp + i,
            lastClaimTime : block.timestamp + i,
            rewardNotClaimed : 0
            })
            );

            nodeOwners.set(account, _nodesOfUser[account].length);
            totalNodesCreated++;
            emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
        }
        //emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
    }

    function burn(address account, uint256 index) external onlyManager {

        uint256 numberOfNodes = _nodesOfUser[account].length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes"
        );

        require(index < numberOfNodes);
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }

    function getNodeInfo(
        address account,
        uint256 id
    ) public view returns (NewNodeEntity memory) {

        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        require(
            nodes.length > 0,
            "CASHOUT ERROR: You don't have nodes"
        );

        bool found = false;
        int256 index = binary_search(nodes, 0, nodes.length, id);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function _getNodeWithCreatime(
        NewNodeEntity[] storage nodes,
        uint256 id
    ) private view returns (NewNodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, id);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function binary_search(
        NewNodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].id == x) {
                return int256(mid);
            } else if (arr[mid].id > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return - 1;
        }
    }

    function addRewardsToNode(address wallet, uint256 nodeIndex, uint256 amount)
    external onlyManager
    {
        require(nodeIndex > 0, "NODE: addRewardsToNode amount must be higher than zero");
        _nodesOfUser[wallet][nodeIndex].rewardNotClaimed += amount;
    }

    function updateNotClaimedRewards()
    internal onlyManager
    {
        for (uint256 i = 0; i < totalNodesCreated; i++) {
            address wallet = nodeOwners.getKeyAtIndex(i);
            for (uint256 j = 0; j < _nodesOfUser[wallet].length; j++) {
                _nodesOfUser[wallet][j].rewardNotClaimed += claimableAmount(_nodesOfUser[wallet][j].lastClaimTime);
                _nodesOfUser[wallet][j].lastClaimTime = block.timestamp;
            }
        }
    }

    function _cashoutNodeReward(address account, uint256 id)
    external onlyManager
    returns (uint256)
    {
        require(id > 0, "NODE: CREATIME must be higher than zero");
        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NewNodeEntity storage node = _getNodeWithCreatime(nodes, id);
        uint256 rewardNode = claimableAmount(node.lastClaimTime) + node.rewardNotClaimed;

        node.rewardNotClaimed = 0;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
    external onlyManager
    returns (uint256)
    {
        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NewNodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += claimableAmount(_node.lastClaimTime) + _node.rewardNotClaimed;

            _node.rewardNotClaimed = 0;
        }
        return rewardsTotal;
    }

    function claimable(NewNodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimInterval <= block.timestamp;
    }

    function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += claimableAmount(nodes[i].lastClaimTime) + nodes[i].rewardNotClaimed;
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 id)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(id > 0, "NODE: CREATIME must be higher than zero");

        NewNodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;

        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );

        NewNodeEntity storage node = _getNodeWithCreatime(nodes, id);
        return claimableAmount(node.lastClaimTime) + node.rewardNotClaimed;
    }

    function claimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        uint256 intervalsPassed = (currentTime).sub(nodeLastClaimTime).div(claimInterval);
        return intervalsPassed.mul(rewardsPerMinute);
    }

    function _getNodesIds(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET IDS NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory ids = uint2str(nodes[0].id);
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            ids = string(abi.encodePacked(ids, separator, uint2str(_node.id)));
        }
        return ids;
    }

    function _getNodesCreationTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory _creationIds = uint2str(nodes[0].id);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationIds = string(
                abi.encodePacked(
                    _creationIds,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationIds;
    }

    function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(claimableAmount(_node.lastClaimTime) + _node.rewardNotClaimed);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(claimableAmount(_node.lastClaimTime) + _node.rewardNotClaimed)
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesExpireTime(address account)
    external
    view
    returns (string memory)
    {
        return "";
    }

    function _migrateNodes(address oldNodeRewardsContractAddress, address[] memory oldNodeRewardsContractUsers, uint256 amount)
    external
    {
        require(oldNodeRewardsContractAddress != address(0), "oldNodeRewardsContractAddress CANT BE ZERO");
        require(oldNodeRewardsContractAddress != address(this), "oldNodeRewardsContract CANT BE SAME ADDRESS");
        require(oldNodeRewardsContractUsers.length > 0, "rewardTokenUsers CANT BE ZERO");

        // Instance old rewards contract for get their nodes
        OldNODERewardManagement oldNodeRewardManagement = OldNODERewardManagement(oldNodeRewardsContractAddress);

        // 1. Loop all users from old node rewards contract
        for (uint256 x = 0; x < oldNodeRewardsContractUsers.length; x++) {

            address user = oldNodeRewardsContractUsers[x];

            OldNODERewardManagement.NodeEntity[] memory nodes = oldNodeRewardManagement.getNodes(user);

            // 3. If users has nodes (nodesCreationTime should be bigger than zero)
            if (nodes.length > 0) {

                // 4. Get all nodes from user
                for (uint256 i = 0; i < nodes.length; i++) {

                    // 5. Get last claim date from users old nodes
                    uint256 lastClaimDate = nodes[i].lastClaimTime;

                    // 6. Calc how much he should can claim from each old node
                    uint256 notClaimedAmount = claimableAmount(lastClaimDate);

                    // 7. Set node creation date before last claim date
                    uint256 creationDate = nodes[i].creationTime;

                    // 8. Create same node number on new contract
                    _nodesOfUser[user].push(
                        NewNodeEntity({
                            id : totalNodesCreated + 1,
                            creationTime : creationDate,
                            lastClaimTime : block.timestamp,
                            rewardNotClaimed : notClaimedAmount
                            })
                    );

                    nodeOwners.set(user, _nodesOfUser[user].length);
                    totalNodesCreated++;
                    _nodesOfUser[user][i].rewardNotClaimed += amount;
                    emit NodeCreated(user, totalNodesCreated, _nodesOfUser[user].length, totalNodesCreated);
                }
            }
        }
    }


    /*
    for (uint256 i = 0; i < totalNodesCreated; i++) {
        address wallet = nodeOwners.getKeyAtIndex(i);
        for (uint256 j = 0; j < _nodesOfUser[wallet].length; j++) {
            _nodesOfUser[wallet][j].rewardNotClaimed += claimableAmount(_nodesOfUser[wallet][j]);
            _nodesOfUser[wallet][j].lastClaimTime = block.timestamp;
        }
    }
*/

    function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NewNodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NewNodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _changeNodePrice(uint256 newNodePrice) external onlyManager {
        nodePrice = newNodePrice;
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyManager {
        rewardsPerMinute = newPrice;
    }

    function _changeClaimInterval(uint256 newTime) external onlyManager {
        claimInterval = newTime;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Address.sol";
import "./IERC20.sol";

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

pragma solidity ^0.8.11;

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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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
pragma solidity ^0.8.11;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
    public
    view
    returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
    public
    view
    returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SafeMath.sol";

contract OldNODERewardManagement {
    using SafeMath for uint256;

    struct NodeEntity {
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 dividendsPaid;
        uint256 expireTime;
    }

    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => bool) public _managers;

    uint256 public nodePrice;

    uint256 public rewardsPerMinute;

    bool public distribution = false;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    uint256 public claimInterval = 60;

    uint256 public stakeNodeStartAmount = 0 * 10 ** 18;
    uint256 public nodeStartAmount = 1 * 10 ** 18;

    event NodeCreated(address indexed from, string name, uint256 index, uint256 totalNodesCreated);

    constructor(
        uint256 _nodePrice,
        uint256 _rewardsPerMinute
    ) {
        _managers[msg.sender] = true;
        nodePrice = _nodePrice;
        rewardsPerMinute = _rewardsPerMinute;
    }

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    function addManager(address manager) external onlyManager {
        _managers[manager] = true;
    }

    function createNode(address account, string memory name, uint256 expireTime) external onlyManager {
        uint256 realExpireTime = 0;
        if (expireTime > 0) {
            realExpireTime = block.timestamp + expireTime;
        }
        _nodesOfUser[account].push(
            NodeEntity({
        creationTime : block.timestamp,
        lastClaimTime : block.timestamp,
        dividendsPaid : 0,
        expireTime : realExpireTime
        })
        );
        totalNodesCreated++;
        emit NodeCreated(account, name, _nodesOfUser[account].length, totalNodesCreated);
    }

    function dividendsOwing(NodeEntity memory node) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        if (currentTime > node.expireTime && node.expireTime > 0) {
            currentTime = node.expireTime;
        }
        uint256 minutesPassed = (currentTime).sub(node.creationTime).div(claimInterval);
        return minutesPassed.mul(rewardsPerMinute).add(node.expireTime > 0 ? stakeNodeStartAmount : nodeStartAmount).sub(node.dividendsPaid);
    }

    function _checkExpired(NodeEntity memory node) private view returns (bool isExpired) {
        return (node.expireTime > 0 && node.expireTime <= block.timestamp);
    }

    function _getNodeByIndex(
        NodeEntity[] storage nodes,
        uint256 index
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        require(index < numberOfNodes, "CASHOUT ERROR: Invalid node");
        return nodes[index];
    }

    function _cashoutNodeReward(address account, uint256 index)
    external
    onlyManager
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeByIndex(nodes, index);
        uint256 rewardNode = dividendsOwing(node);
        node.dividendsPaid += rewardNode;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
    external
    onlyManager
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: NO NODE OWNER");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            uint256 rewardNode = dividendsOwing(_node);
            rewardsTotal += rewardNode;
            _node.lastClaimTime = block.timestamp;
            _node.dividendsPaid += rewardNode;
        }
        return rewardsTotal;
    }

    function getPendingCashoutAllNodesReward(address account)
    external
    view
    returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: NO NODE OWNER");

        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            uint256 rewardNode = dividendsOwing(nodes[i]);
            rewardsTotal += rewardNode;
        }
        return rewardsTotal;
    }

    function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        NodeEntity storage _node;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardCount += dividendsOwing(_node);
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 index)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeByIndex(nodes, index);
        uint256 rewardNode = dividendsOwing(node);
        return rewardNode;
    }

    function _getNodeRewardAmountOf(address account, uint256 index)
    external
    view
    returns (uint256)
    {
        NodeEntity memory node = _getNodeByIndex(_nodesOfUser[account], index);
        return dividendsOwing(node);
    }


    function _getNodesExpireTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _expireTimes = uint2str(nodes[0].expireTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            _expireTimes = string(
                abi.encodePacked(
                    _expireTimes,
                    separator,
                    uint2str(_node.expireTime)
                )
            );
        }
        return _expireTimes;
    }


    function _getNodesCreationTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(dividendsOwing(nodes[0]));
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(dividendsOwing(_node))
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function getNodes(address user) external view returns (NodeEntity[] memory nodes) {
        return _nodesOfUser[user];
    }

    function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _changeStakeNodeStartAmount(uint256 newStartAmount) external onlyManager {
        stakeNodeStartAmount = newStartAmount;
    }

    function _changeNodeStartAmount(uint256 newStartAmount) external onlyManager {
        nodeStartAmount = newStartAmount;
    }

    function _changeNodePrice(uint256 newNodePrice) external onlyManager {
        nodePrice = newNodePrice;
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyManager {
        rewardsPerMinute = newPrice;
    }

    function _changeClaimInterval(uint256 newInterval) external onlyManager {
        claimInterval = newInterval;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return _nodesOfUser[account].length;
    }

    function isNodeOwner(address account) private view returns (bool) {
        return _nodesOfUser[account].length > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }
}