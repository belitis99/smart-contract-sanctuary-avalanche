// contracts/FeeCollector.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IArableSynth.sol";
import "./interfaces/IArableAddressRegistry.sol";
import "./interfaces/IArableFeeCollector.sol";
import "./interfaces/IArableCollateral.sol";
import "./interfaces/IArableExchange.sol";

import "./libs/ArableFees.sol";

/**
 * @author Ian Decentralize
 */
contract ArableFeeCollector is
    Initializable,
    OwnableUpgradeable,
    IArableFeeCollector,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    address public addressRegistry;

    uint256 public epochStartBlock;
    uint256 public epochStartTime;
    uint256 public epochDuration;
    uint256 public epochNumber;

    address[] public rewardTokens;
    mapping(address => bool) public _isRewardToken;

    mapping(address => bool) public isAllowedProvider;
    // lastRewardsIncreaseEpoch[address][rewardToken]
    mapping(address => mapping(address => uint256)) public lastRewardsIncreaseEpoch;
    // claimableRewards[address][rewardToken]
    mapping(address => mapping(address => uint256)) public claimableRewards;
    // claimedRewards[address][rewardToken]
    mapping(address => mapping(address => uint256)) public claimedRewards;
    // totalClaimed[rewardToken]
    mapping(address => uint256) public totalClaimed;
    // totalDistributed[rewardToken]
    mapping(address => uint256) public totalDistributed;

    // amount / FEE_BASE * base3
    uint256 internal constant FEE_BASE = 10000;

    // default model
    ArableFees.Model internal currentModel;

    // could return fees directly or return a contract with model.
    // to keep precision we use a base 3 number where 200 = 2.00 percent.
    // see also how to apply MANTISSA to smaller units.
    mapping(address => mapping(ArableFees.Model => uint256)) public feesPerAssetModel;

    // cumulated fees per asset model could also be pulled from another contract
    mapping(address => mapping(ArableFees.Model => uint256)) public cumulatedFeesPerAssetModel;

    // some account might have discount bonus, could come from another contract.
    // Idealy this would come from the registrant contract

    // TODO: add a call to subscription to set the bonus - pay ACRE for subscription
    mapping(address => mapping(address => uint256)) public accountBonusModel;

    event FeesPaid(address asset, ArableFees.Model model, uint256 fees);
    event IncreaseMinterRewards(address minter, address rewardToken, uint256 amount);
    event Claim(address minter, address rewardToken, uint256 amount);
    event EpochStart(uint256 epochNumber, uint256 epochStartBlock, uint256 epochStartTime);
    event SetEpochTokenRewards(uint256 epochNumber, address rewardToken, uint256 amount);
    event SetRewardTokens(address[] rewardTokens);
    event Pause();
    event Unpause();

    modifier onlyManager() {
        require(
            msg.sender == IArableAddressRegistry(addressRegistry).getArableManager(),
            "ArableFeeCollector: Manager Required!"
        );
        _;
    }

    modifier onlyAllowedProvider() {
        require(isAllowedProvider[msg.sender], "Not an allowed fee info provider");
        _;
    }

    function initialize(
        address addressRegistry_,
        uint256 defaultFees_,
        uint256 epochDuration_
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init();
        __Pausable_init_unchained();

        require(addressRegistry_ != address(0), "Invalid addressRegistry_");

        addressRegistry = addressRegistry_;
        // setting a default fee model
        feesPerAssetModel[address(0)][ArableFees.Model.DEFAULT] = defaultFees_;

        isAllowedProvider[msg.sender] = true;
        epochStartBlock = block.number;
        epochStartTime = block.timestamp;
        epochNumber = 1;
        epochDuration = epochDuration_;
        epochNumber = 0;
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @dev This function will pull the funds from caller and must be approved using estimateFees
     * @param asset_ address of the asset
     * @param amount_ The amount Input
     * @param account_ The account calling
     * @param model_ The model for which the fees apply
     * @return fees
     */
    function calculateFees(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external view override returns (uint256 fees) {
        return _calculateFees(asset_, amount_, account_, model_);
    }

    /**
     * @dev setAssetFeeModel is called within the transaction.(external)
     * @param asset_ address of the asset
     * @param fees_ The fees in base3
     * @param model_ The model
     */
    function setAssetFeeModel(
        address asset_,
        uint256 fees_,
        ArableFees.Model model_
    ) external override onlyManager whenNotPaused {
        require(model_ < ArableFees.Model.MAX, "ArableFeeCollector: Model overflow");
        require(fees_ <= FEE_BASE, "ArableFeeCollector: Fee overflow");
        feesPerAssetModel[asset_][ArableFees.Model(model_)] = fees_;
    }

    /**
     * @dev This function will pull the funds from caller and must be approved using estimateFees
     * @param asset_ address of the asset
     * @param amount_ The amount Input
     * @param account_ The account calling
     * @param model_ The model for which the fees apply
     * @return collectorReceipt to return to the caller
     */
    function payFeesFor(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external override whenNotPaused returns (uint256[] memory collectorReceipt) {
        require(
            asset_ != address(0x0) && account_ != address(0x0),
            "ArableFeeCollector: asset_ and account_ should be set"
        );
        collectorReceipt = new uint256[](2);
        _setCurrentModel(asset_, ArableFees.Model(model_));
        uint256 fees = _calculateFees(asset_, amount_, account_, ArableFees.Model(model_));

        if (fees == 0) {
            collectorReceipt[0] = 0;
            collectorReceipt[1] = amount_;
        } else if (fees > 0) {
            // pull the fees.
            cumulatedFeesPerAssetModel[asset_][currentModel] += fees;
            collectorReceipt[0] = fees;
            // resolving any overflow possible issues
            if (fees >= amount_) {
                collectorReceipt[1] = fees - amount_;
            } else {
                collectorReceipt[1] = amount_ - fees;
            }

            require(
                IArableSynth(asset_).transferFrom(msg.sender, address(this), fees),
                "ArableFeeCollector: Collection Failed!"
            );

            // convert fees to arUSD
            address exchange = IArableAddressRegistry(addressRegistry).getArableExchange();
            IERC20(asset_).approve(exchange, fees);
            IArableExchange(exchange).convertFeesToUsd(asset_, fees);
        }
        _setCurrentModel(asset_, ArableFees.Model(0));
        emit FeesPaid(asset_, ArableFees.Model(model_), fees);

        return collectorReceipt;
    }

    function setAllowedProvider(address provider_) external onlyOwner {
        require(provider_ != address(0), "Invalid provider_");

        isAllowedProvider[provider_] = true;
    }

    function unsetAllowedProvider(address provider_) external onlyOwner {
        require(provider_ != address(0), "Invalid provider_");

        isAllowedProvider[provider_] = false;
    }

    function setAllowedProviders(address[] calldata providers_) external onlyOwner {
        for (uint256 index = 0; index <= providers_.length; index++) {
            require(providers_[index] != address(0), "Invalid providers_");

            isAllowedProvider[providers_[index]] = true;
        }
    }

    function unsetAllowedProviders(address[] calldata providers_) external onlyOwner {
        for (uint256 index = 0; index <= providers_.length; index++) {
            require(providers_[index] != address(0), "Invalid providers_");

            isAllowedProvider[providers_[index]] = false;
        }
    }

    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    function getRewardTokensCount() external view returns (uint256) {
        return rewardTokens.length;
    }

    // by validators
    function increaseMinterRewards(
        address minter,
        address rewardToken,
        uint256 amount
    ) external override onlyAllowedProvider nonReentrant whenNotPaused {
        require(_isRewardToken[rewardToken], "Not a reward token");
        require(lastRewardsIncreaseEpoch[minter][rewardToken] < epochNumber, "Already increased reward for the epoch");

        claimableRewards[minter][rewardToken] += amount;
        totalDistributed[rewardToken] += amount;
        lastRewardsIncreaseEpoch[minter][rewardToken] = epochNumber;
        emit IncreaseMinterRewards(minter, rewardToken, amount);
    }

    function bulkIncreaseMinterRewards(
        address rewardToken,
        address[] calldata minters,
        uint256[] calldata amounts
    ) external override onlyAllowedProvider nonReentrant whenNotPaused {
        require(_isRewardToken[rewardToken], "Not a reward token");
        require(minters.length == amounts.length, "Minters and amounts length should be equal");

        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            uint256 amount = amounts[i];
            if (lastRewardsIncreaseEpoch[minter][rewardToken] >= epochNumber) {
                continue;
            }

            claimableRewards[minter][rewardToken] += amount;
            totalDistributed[rewardToken] += amount;
            lastRewardsIncreaseEpoch[minter][rewardToken] = epochNumber;
            emit IncreaseMinterRewards(minter, rewardToken, amount);
        }
    }

    /**
     * @dev This function will pull the funds from caller and must be approved using estimateFees
     * @param asset_ address of the asset
     * @param amount_ The amount Input
     * @param account_ The account calling
     * @param model_ The model for which the fees apply
     * @return fees
     */
    function _calculateFees(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) internal view returns (uint256 fees) {
        address defaultAsset = address(0);
        ArableFees.Model defaultModel = ArableFees.Model.DEFAULT;
        uint256 assetModelFees = feesPerAssetModel[defaultAsset][defaultModel];
        if (feesPerAssetModel[defaultAsset][model_] != 0) {
            assetModelFees = feesPerAssetModel[address(0)][model_];
        }
        if (feesPerAssetModel[asset_][model_] != 0) {
            assetModelFees = feesPerAssetModel[asset_][model_];
        }

        uint256 accountBonus = accountBonusModel[defaultAsset][account_];
        if (accountBonusModel[asset_][account_] != 0) {
            accountBonus = accountBonusModel[asset_][account_];
        }

        if (assetModelFees >= accountBonus) {
            fees = (amount_ * (assetModelFees - accountBonus)) / FEE_BASE;
        } else {
            fees = (amount_ * (accountBonus - assetModelFees)) / FEE_BASE;
        }
    }

    /**
     * @dev Check if asset have a model.
     * unkown/default model is = 0.
     *
     * @param asset_ The asset
     * @param model_ The model
     */
    function _setCurrentModel(address asset_, ArableFees.Model model_) internal {
        if (feesPerAssetModel[asset_][model_] == uint256(ArableFees.Model.DEFAULT)) {
            currentModel = ArableFees.Model.DEFAULT;
        } else {
            currentModel = ArableFees.Model(model_);
        }
    }

    function setRewardTokens(address[] memory _rewardTokens) public override onlyOwner {
        deleteRewardTokens();
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            require(rewardToken != address(0), "Invalid rewardTokens");

            rewardTokens.push(rewardToken);
            require(!_isRewardToken[rewardToken], "duplicated token");
            _isRewardToken[rewardToken] = true;
        }
        emit SetRewardTokens(_rewardTokens);
    }

    function deleteRewardTokens() public override onlyOwner {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _isRewardToken[rewardTokens[i]] = false;
        }
        while (rewardTokens.length > 0) {
            rewardTokens.pop();
        }
    }

    // by validators
    function startNewEpoch() public override onlyAllowedProvider whenNotPaused {
        require(block.timestamp > epochStartTime + epochDuration, "not enough time passed for epoch");
        epochStartBlock = block.number;
        epochStartTime = block.timestamp;
        epochNumber = epochNumber + 1;

        emit EpochStart(epochNumber, epochStartBlock, epochStartTime);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            emit SetEpochTokenRewards(epochNumber, rewardToken, getTotalDistributableRewards(rewardToken));
        }
    }

    function claimReward(address rewardToken) public override nonReentrant whenNotPaused {
        _claimReward(msg.sender, rewardToken);
    }

    function _claimReward(address minter, address rewardToken) internal {
        require(_isRewardToken[rewardToken], "Not a reward token");
        require(claimableRewards[minter][rewardToken] > claimedRewards[minter][rewardToken], "empty rewards");
        address collateral = IArableAddressRegistry(addressRegistry).getArableCollateral();
        IArableCollateral collateralContract = IArableCollateral(collateral);
        require(collateralContract.userRiskRate(minter) <= 1 ether, "risk rate should be lower than 100%");

        uint256 claimAmount = claimableRewards[minter][rewardToken] - claimedRewards[minter][rewardToken];
        claimedRewards[minter][rewardToken] += claimAmount;
        totalClaimed[rewardToken] += claimAmount;
        IArableSynth(rewardToken).transfer(minter, claimAmount);
        emit Claim(msg.sender, rewardToken, claimAmount);
    }

    function estimatedReward(address minter, address rewardToken) public view override returns (uint256) {
        return claimableRewards[minter][rewardToken] - claimedRewards[minter][rewardToken];
    }

    function getTotalDistributableRewards(address rewardToken) public view override returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this)) + totalClaimed[rewardToken] - totalDistributed[rewardToken];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArableSynth is IERC20 {
    function mint(address toAddress, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function safeMint(address toAddress, uint256 amount) external;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/**
 * @title Provider interface for Arable
 * @dev
 */
interface IArableAddressRegistry {
    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address address_) external;

    function getArableOracle() external view returns (address);

    function setArableOracle(address arableOracle_) external;

    function getArableExchange() external view returns (address);

    function setArableExchange(address arableExchange_) external;

    function getArableManager() external view returns (address);

    function setArableManager(address arableManager_) external;

    function getArableFarming() external view returns (address);

    function setArableFarming(address arableFarming_) external;

    function getArableCollateral() external view returns (address);

    function setArableCollateral(address arableCollateral_) external;

    function getArableLiquidation() external view returns (address);

    function setArableLiquidation(address arableLiquidation_) external;

    function getArableFeeCollector() external view returns (address);

    function setArableFeeCollector(address arableFeeCollector_) external;
}

// interfaces/IArableFeeCollector.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/ArableFees.sol"; 

interface IArableFeeCollector {
    function calculateFees(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external view returns (uint256 fees);

    function setAssetFeeModel(
        address asset_,
        uint256 fees_,
        ArableFees.Model model_
    ) external;

    function payFeesFor(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external returns (uint256[] memory collectorReceipt);

    function setRewardTokens(address[] memory _rewardTokens) external;

    function deleteRewardTokens() external;

    function startNewEpoch() external;

    function increaseMinterRewards(address minter, address rewardToken, uint256 amount) external;

    function bulkIncreaseMinterRewards(
        address rewardToken,
        address[] calldata minters,
        uint256[] calldata amounts
    ) external;

    function claimReward(address rewardToken) external;

    function estimatedReward(address minter, address rewardToken) external view returns (uint256);

    function getTotalDistributableRewards(address rewardToken) external view  returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableCollateral {
    function addToDebt(uint amount) external returns (bool);
    function removeFromDebt(uint256 amount) external returns (bool);
    function getTotalDebt() external returns (uint);
    function addSupportedCollateral(address token, uint allowedRate) external returns (bool);
    function removeSupportedCollateral(address token) external returns (bool);
    function changeAllowedRate(address token, uint newAllowedRate) external returns (bool);
    function userRiskRate(address user) external view returns (uint256);
    function maxIssuableArUSD(address user) external view returns (uint);
    function currentDebt(address user) external view returns (uint);
    function calculateCollateralValue(address user) external view returns (uint);
    function _liquidateCollateral(address user, address beneficiary, uint liquidationAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableExchange {
    function swapSynths(address inToken, uint256 inAmount, address outToken) external;
    function convertFeesToUsd(address inToken, uint256 inAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ArableFees {
    enum Model {
        DEFAULT,           // default fees if asset is unknow (0)
        SETUP_FARM,        // new farm fees
        EXIT_FARM,         // exit farm fees
        REWARD,            // reward fees
        SYNTHS_X,          // synthetic asset exchange fees
        SYNTHS_MINT,       // synthetic asset mint fees
        SYNTHS_BURN,       // synthetic asset burn fees
        LIQUIDATE,         // liquidation fees
        MAX                // maximumn value (8)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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