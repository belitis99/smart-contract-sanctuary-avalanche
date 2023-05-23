/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-22
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// File: JANTU.sol


pragma solidity ^0.8.10;
/**
               _  __          
__      _____ | |/ _|         
\ \ /\ / / _ \| | |_          
 \ V  V / (_) | |  _|         
  \_/\_/ \___/|_|_|           
                              
                 _ _        _ 
  ___ __ _ _ __ (_) |_ __ _| |
 / __/ _` | '_ \| | __/ _` | |
| (_| (_| | |_) | | || (_| | |
 \___\__,_| .__/|_|\__\__,_|_|
          |_|                 
*/





contract Simple is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    IERC20MetadataUpgradeable public usdc;
    address public marketingWallet;
    address public developmentWallet1;
    address public developmentWallet2;
    address public multiSigWallet;
    uint256 public basePercent;
    uint256 public teamPercentMultiplier;
    uint256 public ownerFeePercent;
    uint256 public marketingFeePercent;
    uint256 public dev1FeePercent;
    uint256 public dev2FeePercent;
    uint256 public lotteryFeePercent;
    uint256 public lotteryPercent;
    uint256 public referrerPercent;
    uint256 public referralPercent;
    uint256 public percentDivider;
    uint256 public minDeposit;
    uint256 public maxDeposit;
    uint256 public timeStep;
    uint256 public claimDuration;
    uint256 public accumulationDuration;
    uint256 public lockDuration;

    function initialize(address _token) public initializer {
        usdc = IERC20MetadataUpgradeable(
            _token
        );
        marketingWallet = 0x57741A3F319D526F9DdBa1D181207C8bD06c2914;
        developmentWallet1 = 0x7f35be372873e06c15DD7f9494A426ACab99C6De;
        developmentWallet2 = 0x7DB1A2f972652020e8664005B6119F21A64C39B8;
        multiSigWallet = 0x05c09F12e03a56FbC03EdB8acB2ef7933E1Ff45C;
        basePercent = 1_00;
        teamPercentMultiplier = 10;
        ownerFeePercent = 3_00;
        marketingFeePercent = 4_00;
        dev1FeePercent = 1_00;
        dev2FeePercent = 1_00;
        lotteryFeePercent = 1_00;
        lotteryPercent = 30_00;
        referrerPercent = 1_50;
        referralPercent = 1_50;
        percentDivider = 100_00;
        minDeposit = 50e18;
        maxDeposit = 100_000e18;
        timeStep = 1 minutes;
        claimDuration = 7 minutes;
        accumulationDuration = 10 minutes;
        lockDuration = 60 minutes;
    }

    uint256 public totalStaked;
    uint256 public totalWithdrawan;
    uint256 public totalRefRewards;
    uint256 public uniqueStakers;
    uint256 public topDepositThisWeek;
    uint256 public topTeamThisWeek;
    uint256 public lotteryPool;
    uint256 public uniqueTeamId;
    uint256 public currentWeek;
    uint256 public launchTime;
    uint256 public haltAccStartTime;
    uint256 public haltAccEndTime;
    bool public haltDeposits;
    bool public haltWithdraws;
    bool public haltAccumulation;
    bool public launched;

    uint256[10] public requiredTeamUsers;
    uint256[10] public requiredTeamAmount;

    struct StakeData {
        uint256 amount;
        uint256 checkpoint;
        uint256 claimedReward;
        uint256 startTime;
        bool isActive;
    }

    struct User {
        bool isExists;
        address referrer;
        uint256 referrals;
        uint256 referralRewards;
        uint256 teamId;
        uint256 stakeCount;
        uint256 currentStaked;
        uint256 totalStaked;
        uint256 totalWithdrawan;
    }

    struct TeamData {
        address Lead;
        string teamName;
        uint256 teamCount;
        uint256 teamAmount;
        uint256 currentPercent;
        address[] teamMembers;
        mapping(uint256 => uint256) lotteryAmount;
        mapping(uint256 => uint256) weeklyDeposits;
    }

    mapping(address => User) internal users;
    mapping(uint256 => TeamData) internal teams;
    mapping(address => mapping(uint256 => StakeData)) internal userStakes;
    mapping(address => mapping(uint256 => bool)) internal isLotteryClaimed;
    mapping(uint256 => uint256) internal winnersHistory;
    mapping(address => bool) internal isUserMigrated;
    mapping(uint256 => bool) internal isTeamMigrated;

    event STAKE(address Staker, uint256 amount);
    event CLAIM(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);
    event LOTTERY(
        uint256 topTeamThisWeek,
        uint256 lotteryAmount,
        uint256 lastWeekTopDeposit
    );

    function updateWeekly() public {
        if (currentWeek != calculateWeek()) {
            checkForLotteryWinner();
            currentWeek = calculateWeek();
            topDepositThisWeek = 0;
        }
    }

    function stake(address _referrer, uint256 _amount) public {
        require(launched, "Wait for launch");
        require(!haltDeposits, "Admin halt deposits");
        updateWeekly();
        User storage user = users[msg.sender];
        require(_amount >= minDeposit, "Amount less than min amount");
        require(
            user.currentStaked + _amount <= maxDeposit,
            "Amount more than max amount"
        );
        if (!user.isExists) {
            user.isExists = true;
            uniqueStakers++;
        }

        totalStaked += _amount;
        usdc.transferFrom(msg.sender, address(this), _amount);
        takeFee(_amount);
        _amount = (_amount * 90) / 100;

        StakeData storage userStake = userStakes[msg.sender][user.stakeCount];
        userStake.amount = _amount;
        userStake.startTime = block.timestamp;
        userStake.checkpoint = block.timestamp;
        userStake.isActive = true;
        user.stakeCount++;
        user.totalStaked += _amount;
        user.currentStaked += _amount;

        if (_referrer == msg.sender) {
            _referrer = address(0);
        }

        if (user.referrer == address(0)) {
            if (user.teamId == 0) {
                setReferrer(msg.sender, _referrer);
            }
        }

        if (user.referrer != address(0)) {
            distributeRefReward(msg.sender, _amount);
        }

        updateTeam(msg.sender, _amount);

        emit STAKE(msg.sender, _amount);
    }

    function setReferrer(address _user, address _referrer) private {
        User storage user = users[_user];

        if (_referrer == address(0)) {
            createTeam(_user);
        } else if (_referrer != _user) {
            user.referrer = _referrer;
        }

        if (user.referrer != address(0)) {
            users[user.referrer].referrals++;
        }
    }

    function distributeRefReward(address _user, uint256 _amount) private {
        User storage user = users[_user];

        uint256 userRewards = _amount.mul(referralPercent).div(percentDivider);
        uint256 refRewards = _amount.mul(referrerPercent).div(percentDivider);

        usdc.transfer(_user, userRewards);
        usdc.transfer(user.referrer, refRewards);

        user.referralRewards += userRewards;
        users[user.referrer].referralRewards += refRewards;
        totalRefRewards += userRewards;
        totalRefRewards += refRewards;
    }

    function createTeam(address _user) private {
        User storage user = users[_user];
        user.teamId = ++uniqueTeamId;
        TeamData storage newTeam = teams[user.teamId];
        newTeam.Lead = _user;
        newTeam.teamName = Strings.toString(user.teamId);
        newTeam.teamMembers.push(_user);
        newTeam.teamCount++;
    }

    function updateTeam(address _user, uint256 _amount) private {
        User storage user = users[_user];

        if (user.teamId == 0) {
            user.teamId = users[user.referrer].teamId;
            teams[user.teamId].teamCount++;
            teams[user.teamId].teamMembers.push(_user);
        }

        TeamData storage team = teams[user.teamId];
        team.teamAmount += _amount;
        team.weeklyDeposits[currentWeek] += _amount;
        if (team.weeklyDeposits[currentWeek] > topDepositThisWeek) {
            topDepositThisWeek = team.weeklyDeposits[currentWeek];
            topTeamThisWeek = user.teamId;
        }

        uint256 amountIndex = team.teamAmount /
            (requiredTeamAmount[0] * 10 ** usdc.decimals());
        uint256 countIndex = team.teamCount / requiredTeamUsers[0];
        if (amountIndex == countIndex) {
            team.currentPercent = amountIndex * teamPercentMultiplier;
        } else if (amountIndex < countIndex) {
            team.currentPercent = amountIndex * teamPercentMultiplier;
        } else {
            team.currentPercent = countIndex * teamPercentMultiplier;
        }
        if (team.currentPercent > 100) {
            team.currentPercent = 100;
        }
    }

    function takeFee(uint256 _amount) private {
        usdc.transfer(
            _owner,
            (_amount * ownerFeePercent) / percentDivider
        );
        usdc.transfer(
            marketingWallet,
            (_amount * marketingFeePercent) / percentDivider
        );
        usdc.transfer(
            developmentWallet1,
            (_amount * dev1FeePercent) / percentDivider
        );
        usdc.transfer(
            developmentWallet2,
            (_amount * dev2FeePercent) / percentDivider
        );
        lotteryPool += (_amount * lotteryFeePercent) / percentDivider;
    }

    function claim(uint256 _index) public {
        require(launched, "Wait for launch");
        require(!haltWithdraws, "Admin halt withdrawls");
        updateWeekly();
        User storage user = users[msg.sender];
        StakeData storage userStake = userStakes[msg.sender][_index];
        require(_index < user.stakeCount, "Invalid index");
        require(userStake.isActive, "Already withdrawn");
        require(
            block.timestamp >= userStake.checkpoint + claimDuration,
            "Wait for claim time"
        );
        uint256 rewardAmount;
        rewardAmount = calculateReward(msg.sender, _index);
        require(rewardAmount > 0, "Can't claim 0");
        usdc.transfer(msg.sender, rewardAmount);
        userStake.checkpoint = block.timestamp;
        userStake.claimedReward += rewardAmount;
        user.totalWithdrawan += rewardAmount;
        totalWithdrawan += rewardAmount;

        emit CLAIM(msg.sender, rewardAmount);
    }

    function claimAll() public {
        require(launched, "Wait for launch");
        require(!haltWithdraws, "Admin halt withdrawls");
        updateWeekly();

        User storage user = users[msg.sender];
        uint256 claimableReward;
        for (uint i; i < user.stakeCount; i++) {
            StakeData storage userStake = userStakes[msg.sender][i];
            if (
                userStake.isActive &&
                block.timestamp >= userStake.checkpoint + claimDuration
            ) {
                uint256 rewardAmount;
                rewardAmount = calculateReward(msg.sender, i);
                userStake.checkpoint = block.timestamp;
                userStake.claimedReward += rewardAmount;
                claimableReward += rewardAmount;
            }
        }
        require(claimableReward > 0, "Can't claim 0");
        usdc.transfer(msg.sender, claimableReward);

        user.totalWithdrawan += claimableReward;
        totalWithdrawan += claimableReward;

        emit CLAIM(msg.sender, claimableReward);
    }

    function withdraw(uint256 _index) public {
        require(launched, "Wait for launch");
        require(!haltWithdraws, "Admin halt withdrawls");
        updateWeekly();

        User storage user = users[msg.sender];
        StakeData storage userStake = userStakes[msg.sender][_index];
        require(_index < user.stakeCount, "Invalid index");
        require(userStake.isActive, "Already withdrawn");
        require(
            block.timestamp >= userStake.startTime + lockDuration,
            "Wait for end time"
        );

        usdc.transfer(msg.sender, userStake.amount);
        userStake.isActive = false;
        userStake.checkpoint = block.timestamp;
        user.currentStaked -= userStake.amount;
        user.totalWithdrawan += userStake.amount;
        totalWithdrawan += userStake.amount;

        emit WITHDRAW(msg.sender, userStake.amount);
    }

    function checkForLotteryWinner() private {
        uint256 lotteryAmount = (lotteryPool * lotteryPercent) / percentDivider;
        teams[topTeamThisWeek].lotteryAmount[currentWeek] = lotteryAmount;
        winnersHistory[currentWeek] = topTeamThisWeek;
        lotteryPool -= lotteryAmount;

        emit LOTTERY(topTeamThisWeek, lotteryAmount, topDepositThisWeek);
    }

    function claimLottery() public {
        User storage user = users[msg.sender];
        TeamData storage team = teams[user.teamId];

        require(
            !isLotteryClaimed[msg.sender][currentWeek - 1],
            "Already Claimed"
        );
        require(team.lotteryAmount[currentWeek - 1] > 0, "No reward to Claim");

        uint256 userShare = (user.currentStaked * percentDivider) /
            team.teamAmount;
        usdc.transfer(
            msg.sender,
            (team.lotteryAmount[currentWeek - 1] * userShare) / percentDivider
        );
        isLotteryClaimed[msg.sender][currentWeek - 1] = true;
    }

    /**
        Getter functions for Public
     */

    function calculateWeek() public view returns (uint256) {
        return (block.timestamp - launchTime) / (7 * timeStep);
    }

    function calculateReward(
        address _user,
        uint256 _index
    ) public view returns (uint256 _reward) {
        if (haltAccumulation) return 0;
        StakeData storage userStake = userStakes[_user][_index];
        TeamData storage team = teams[users[_user].teamId];
        uint256 rewardDuration = block.timestamp.sub(userStake.checkpoint);
        if (userStake.checkpoint < haltAccStartTime) {
            rewardDuration =
                rewardDuration -
                (haltAccEndTime - haltAccStartTime);
        }
        if (rewardDuration > accumulationDuration) {
            rewardDuration = accumulationDuration;
        }
        _reward = userStake
            .amount
            .mul(rewardDuration)
            .mul(basePercent + team.currentPercent)
            .div(percentDivider.mul(timeStep));
    }

    function getUserInfo(
        address _user
    )
        public
        view
        returns (
            bool _isExists,
            uint256 _stakeCount,
            address _referrer,
            uint256 _referrals,
            uint256 _referralRewards,
            uint256 _teamId,
            uint256 _currentStaked,
            uint256 _totalStaked,
            uint256 _totalWithdrawan
        )
    {
        User storage user = users[_user];
        _isExists = user.isExists;
        _stakeCount = user.stakeCount;
        _referrer = user.referrer;
        _referrals = user.referrals;
        _referralRewards = user.referralRewards;
        _teamId = user.teamId;
        _currentStaked = user.currentStaked;
        _totalStaked = user.totalStaked;
        _totalWithdrawan = user.totalWithdrawan;
    }

    function getUserTokenStakeInfo(
        address _user,
        uint256 _index
    )
        public
        view
        returns (
            uint256 _amount,
            uint256 _checkpoint,
            uint256 _claimedReward,
            uint256 _startTime,
            bool _isActive
        )
    {
        StakeData storage userStake = userStakes[_user][_index];
        _amount = userStake.amount;
        _checkpoint = userStake.checkpoint;
        _claimedReward = userStake.claimedReward;
        _startTime = userStake.startTime;
        _isActive = userStake.isActive;
    }

    function getUserLotteryClaimedStatus(
        address _user,
        uint256 _week
    ) public view returns (bool _status) {
        _status = isLotteryClaimed[_user][_week];
    }

    function getTeamInfo(
        uint256 _teamId
    )
        public
        view
        returns (
            address _Lead,
            string memory _teamName,
            uint256 _teamCount,
            uint256 _teamAmount,
            uint256 _currentPercent
        )
    {
        TeamData storage team = teams[_teamId];
        _Lead = team.Lead;
        _teamName = team.teamName;
        _teamCount = team.teamCount;
        _teamAmount = team.teamAmount;
        _currentPercent = team.currentPercent;
    }

    function getAllTeamMembers(
        uint256 _teamId,
        uint256 _index
    ) public view returns (address _teamMember) {
        _teamMember = teams[_teamId].teamMembers[_index];
    }

    function getTeamLotteryAmount(
        uint256 _teamId,
        uint256 _week
    ) public view returns (uint256 _amount) {
        _amount = teams[_teamId].lotteryAmount[_week];
    }

    function getTeamWeeklyDepositAmount(
        uint256 _teamId,
        uint256 _week
    ) public view returns (uint256 _amount) {
        _amount = teams[_teamId].weeklyDeposits[_week];
    }

    function getWinnersHistory(
        uint256 _week
    ) public view returns (uint256 _team) {
        _team = winnersHistory[_week];
    }

    function getUserMigrationStatus(address _user) public view returns (bool) {
        return isUserMigrated[_user];
    }

    function getTeamMigrationStatus(
        uint256 _teamId
    ) public view returns (bool) {
        return isTeamMigrated[_teamId];
    }

    function getContractBalance() public view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /*
        Setter functions For Owner
    */

    function migrateAllStateValues(
        uint256[10] memory _values
    ) external onlyOwner {
        totalStaked = _values[0];
        totalWithdrawan = _values[1];
        totalRefRewards = _values[2];
        uniqueStakers = _values[3];
        topDepositThisWeek = _values[4];
        topTeamThisWeek = _values[5];
        lotteryPool = _values[6];
        uniqueTeamId = _values[7];
        currentWeek = _values[8];
        launchTime = _values[9];
        launched = true;
    }

    function launch() external onlyOwner {
        require(!launched, "Already launched");
        launched = true;
        launchTime = block.timestamp;
    }

    function setHaltDeposits(bool _state) external onlyOwner {
        haltDeposits = _state;
    }

    function setHaltWithdraws(bool _state) external onlyOwner {
        haltWithdraws = _state;
    }

    function setHaltAccumulation(bool _state) external onlyOwner {
        haltAccumulation = _state;
        if (_state) {
            haltAccStartTime = block.timestamp;
        } else {
            haltAccEndTime = block.timestamp;
        }
    }

    function migrateFunds(address _token, uint256 _amount) external {
        require(msg.sender == multiSigWallet, "Not a multisig");
        IERC20MetadataUpgradeable(_token).transfer(_owner, _amount);
    }

    function SetTeamName(string memory _name) external {
        TeamData storage team = teams[users[msg.sender].teamId];
        require(msg.sender == team.Lead, "Not a leader");
        team.teamName = _name;
    }

    function SetDepositLimits(uint256 _min, uint256 _max) external onlyOwner {
        minDeposit = _min;
        maxDeposit = _max;
    }

    function setFeeWallets(
        address _ownerWallet,
        address _marketingWallet,
        address _developmentWallet1,
        address _developmentWallet2
    ) external onlyOwner {
        _owner = _ownerWallet;
        marketingWallet = _marketingWallet;
        developmentWallet1 = _developmentWallet1;
        developmentWallet2 = _developmentWallet2;
    }

    function setMultiSigWallet(address _newWallet) external {
        require(msg.sender == multiSigWallet, "Not a multisig");
        multiSigWallet = _newWallet;
    }

    function setContracts(
        address _newToken
    ) external onlyOwner {
        usdc = IERC20MetadataUpgradeable(_newToken);
    }

    function setBasePercent(
        uint256 _basePercent,
        uint256 _teamPercent
    ) external onlyOwner {
        basePercent = _basePercent;
        teamPercentMultiplier = _teamPercent;
    }
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}