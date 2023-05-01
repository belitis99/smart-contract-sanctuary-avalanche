// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/plugins/IYieldBooster.sol";
import "../interfaces/tokens/ITokenManager.sol";


contract Farms is ReentrancyGuard, Ownable, Pausable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  // Counter for total number of farms created
  uint256 public totalFarms;
  // Contract address for the Steady token
  address public immutable steady;
  // Contract address for the Token Manager
  address public tokenManager;
  // Address for Yield Booster plugin for multiplier
  address public yieldBooster;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  uint256 public constant MAX_REWARDS_SPLIT = 100 * 1e18; // 100%
  uint256 public constant MIN_MULTIPLIER = 1 * 1e18; // 1x

  /* ========== STRUCTS ========== */

  struct Farm {
    // Unique id number of farm
    uint256 id;
    // Boolean for whether farm is active or not
    bool active;
    // Contract address for the staked token
    address stakedToken;
    // Amount of rewards to be distributed per second
    uint256 rewardsDistributionRate;
    // Internal calculation of rewards accrued per staked token
    uint256 rewardsPerStakedToken;
    // Block timestamp which this farm contract was last updated at
    uint256 lastUpdatedAt;
    // Total amount of tokens staked in this farm
    uint256 totalStaked;
    // Total amount of boosted points in this farm
    uint256 totalPoints;
    // Total amount of reward tokens deposited in this farm
    uint256 totalRewards;
    // % split of total rewards to be given in steady; 100% = 1e18
    uint256 esSteadySplit;
    // Maximum multiplier in 1e18
    uint256 maxMultiplier;
    // Timestamp when farm ends
    uint256 endTime;
  }

  struct Position {
    // Amount of tokens staked by user in a farm position
    uint256 stakedAmount;
    // Calculation for tracking rewards owed to user based on stake changes
    uint256 rewardsDebt;
    // Total rewards redeemed by user
    uint256 rewardsRedeemed;
    // Amount of boosted points by user in a farm position
    uint256 pointsAmount;
    // time when user makes last updates to stake
    uint256 lastUpdatedAt;
  }

  /* ========== MAPPINGS ========== */

  // Mapping of farm id to Farm struct
  mapping(uint256 => Farm) public farms;
  // Mapping of farm id to user position address to Position struct
  mapping(uint256 => mapping(address => Position)) public positions;

  /* ========== EVENTS ========== */

  event Stake(uint256 indexed farmId, address indexed user, address token, uint256 amount);
  event Unstake(uint256 indexed farmId, address indexed user, address token, uint256 amount);
  event Claim(uint256 indexed farmId, address indexed user, address token, uint256 amount);
  event Boost(uint256 indexed farmId, address indexed user, uint256 amount);
  event Unboost(uint256 indexed farmId, address indexed user, uint256 amount);
  event UpdateActive(uint256 indexed farmId, bool active);
  event UpdateRewardsDistributionRate(uint256 indexed farmId, uint256 _rate);
  event UpdateEsSteadySplit(uint256 indexed farmId, uint256 _esSteadySplit);
  event UpdateMaxMultiplier(uint256 indexed farmId, uint256 _maxMultiplier);
  event UpdateEndTime(uint256 indexed farmId, uint256 _endTime);
  event UpdateYieldBooster(address indexed caller, uint256 timestamp);
  event UpdateTokenManager(address indexed tokenManager);

  /* ========== MODIFIERS ========== */

  /**
    * Only allow approved addresses for keepers
  */
  modifier onlyYieldBooster() {
    require(msg.sender == yieldBooster, "Only YieldBooster caller allowed");
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor(address _steady, address _tokenManager) {
    require(_steady != address(0), "invalid 0 address");
    require(_tokenManager != address(0), "invalid 0 address");

    steady = _steady;
    tokenManager = _tokenManager;

    IERC20(steady).approve(address(tokenManager), type(uint256).max);
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
  * Calculate the current reward accrued per token staked
  * @param _id  Unique id of farm
  * @param _lastUpdated  Timestamp of position's last update
  * @return currentRewardPerStakedToken Current reward per staked token
  */
  function currentRewardPerStakedToken(uint256 _id, uint256 _lastUpdated) private view returns (uint256) {
    Farm storage farm = farms[_id];

    if (farm.totalStaked <= 0) {
      return farm.rewardsDistributionRate;
    }

    uint256 time = block.timestamp > farm.endTime ? farm.endTime : block.timestamp;

    if (time <= _lastUpdated) return 0;

    return (time - _lastUpdated)
            * farm.rewardsDistributionRate
            * SAFE_MULTIPLIER
            / farm.totalStaked
            + farm.rewardsPerStakedToken;
  }

  /**
  * Returns the reward tokens currently accrued but not yet redeemed to a user
  * @param _id  Unique id of farm
  * @param _user  Address of a user
  * @return rewardsEarned Total rewards accrued to user
  */
  function rewardsEarned(uint256 _id, address _user) public view returns (uint256) {
    Position memory position = positions[_id][_user];
    // TODO
    // Farm memory farm = farms[_id];

    if (currentRewardPerStakedToken(_id, position.lastUpdatedAt) == 0) return 0;

    return ((position.stakedAmount * currentRewardPerStakedToken(_id, position.lastUpdatedAt)
    // return ((position.stakedAmount * currentRewardPerStakedToken(_id, farm.lastUpdatedAt)
            * getRewardMultiplier(_id, _user)
            / SAFE_MULTIPLIER)
            - position.rewardsDebt)
            / SAFE_MULTIPLIER;
  }

  /**
  * Returns the reward multiplier of a user's farm position
  * @param _id  Unique id of farm
  * @param _user  Address of a user
  * @return multiplier  Multiplier in 1e18
  */
  function getRewardMultiplier(uint256 _id, address _user) public view returns (uint256) {
    if (yieldBooster != address(0)) {
      Farm memory farm = farms[_id];
      Position memory position = positions[_id][_user];

      return IYieldBooster(yieldBooster).getMultiplier(
        position.stakedAmount,
        farm.totalStaked,
        position.pointsAmount,
        farm.totalPoints,
        farm.maxMultiplier
      );
    } else {
      return MIN_MULTIPLIER;
    }
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
  Update farm's reward per staked token value
  * @param _id  Unique id of farm
  */
  function _updateFarm(uint256 _id) internal {
    Farm memory farm = farms[_id];

    if (farm.totalStaked > 0 && block.timestamp < farm.endTime)  {
      farm.rewardsPerStakedToken = (block.timestamp - farm.lastUpdatedAt)
        * farm.rewardsDistributionRate
        * SAFE_MULTIPLIER
        / farm.totalStaked
        + farm.rewardsPerStakedToken;
    }

    if (farm.lastUpdatedAt != farm.endTime) {
      farm.lastUpdatedAt = block.timestamp < farm.endTime ? block.timestamp
                                                          : farm.endTime;
    }

    farms[_id] = farm;
  }

  /**
  * Private function used for updating the user rewardsDebt variable
  * Called when user's stake changes
  * @param _id  Unique id of farm
  * @param _user  Address of a user
  * @param _amount  Amount of new tokens staked or amount of tokens left in farm
  */
  function _updateUserRewardsDebt(uint256 _id, address _user, uint256 _amount) private {
    Position storage position = positions[_id][_user];

    position.rewardsDebt = position.rewardsDebt
                          + (_amount * farms[_id].rewardsPerStakedToken
                          * getRewardMultiplier(_id, _user)
                          / SAFE_MULTIPLIER);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
  * External function called when a user wants to stake tokens
  * Called when user is depositing tokens to stake
  * @param _id  Unique id of farm
  * @param _amount  Amount of tokens to stake
  */
  function stake(uint256 _id, uint256 _amount) external nonReentrant whenNotPaused {
    require(farms[_id].active, "Farm is not active");
    require(_amount > 0, "Cannot stake 0");

    claim(_id);

    _updateFarm(_id);

    Position storage position = positions[_id][msg.sender];
    Farm storage farm = farms[_id];

    position.stakedAmount = position.stakedAmount + _amount;
    _updateUserRewardsDebt(_id, msg.sender, position.stakedAmount);
    position.lastUpdatedAt = block.timestamp;
    farm.totalStaked = farm.totalStaked + _amount;
    IERC20(farm.stakedToken).safeTransferFrom(msg.sender, address(this), _amount);

    emit Stake(_id, msg.sender, farm.stakedToken, _amount);
  }

  /**
  * External function called when a user wants to unstake tokens
  * Called when user is withdrawing staked tokens
  * @param _id  Unique id of farm
  * @param _amount  Amount of tokens to withdraw/unstake
  */
  function unstake(uint256 _id, uint256 _amount)
    public
    nonReentrant
    whenNotPaused
  {
    require(_amount > 0, "Cannot unstake 0");

    Position storage position = positions[_id][msg.sender];

    require(_amount <= position.stakedAmount, "Cannot unstake more than staked");

    claim(_id);

    _updateFarm(_id);
    position.rewardsDebt = 0;
    position.stakedAmount = position.stakedAmount - _amount;
    _updateUserRewardsDebt(_id, msg.sender, position.stakedAmount);
    position.lastUpdatedAt = block.timestamp;

    Farm storage farm = farms[_id];
    farm.totalStaked = farm.totalStaked - _amount;
    IERC20(farm.stakedToken).safeTransfer(msg.sender, _amount);

    emit Unstake(_id, msg.sender, farm.stakedToken, _amount);
  }

  /**
  * External function called when a user wants to redeem reward tokens earned
  * @param _id  Unique id of farm
  */
  function claim(uint256 _id) public whenNotPaused {
    uint256 rewards = rewardsEarned(_id, msg.sender);

    if (rewards > 0) {
      Farm storage farm = farms[_id];

      require(
        farm.totalRewards >= rewards,
        "Rewards deposited in farm less than rewards claimable"
      );

      Position memory position = positions[_id][msg.sender];

      position.rewardsRedeemed = position.rewardsRedeemed + rewards;
      position.rewardsDebt += rewards;
      // position.rewardsDebt = position.stakedAmount
      //                        * currentRewardPerStakedToken(_id, block.timestamp)
      //                        * getRewardMultiplier(_id, msg.sender)
      //                        / SAFE_MULTIPLIER;
      position.lastUpdatedAt = block.timestamp;

      positions[_id][msg.sender] = position;

      farm.totalRewards -= rewards;

      if (farm.esSteadySplit > 0) {
        uint256 esSteadyAmount = rewards * farm.esSteadySplit / SAFE_MULTIPLIER;
        uint256 steadyAmount = rewards - esSteadyAmount;

        IERC20(steady).safeTransfer(msg.sender, steadyAmount);
        ITokenManager(tokenManager).convertTo(esSteadyAmount, msg.sender);
        } else {
        IERC20(steady).safeTransfer(msg.sender, rewards);
      }

      emit Claim(_id, msg.sender, steady, rewards);
    }
  }

  /**
  * External function called when a user wants to redeem all accrued reward tokens
  * @param _ids  Array of farm ids to claim from
  */
  function claimAll(uint256[] calldata _ids) public nonReentrant whenNotPaused {
    for (uint256 i = 0; i < _ids.length;) {
      claim(_ids[i]);
      unchecked { i++; }
    }
  }

  /**
  * Boost a farm position with esSteady to increase multiplier for rewards
  * Callable only by the YieldBooster contract
  * @param _id  Unique id of farm
  * @param _user  Address of user farm position
  * @param _amount  Amount of esSteady points to boost this position
  */
  function boost(
    uint256 _id,
    address _user,
    uint256 _amount
  ) external nonReentrant whenNotPaused onlyYieldBooster {
    require(farms[_id].active, "Farm is not active");
    require(_user != address(0), "Invalid zero address");
    require(_amount > 0, "Cannot boost 0");

    claim(_id);

    _updateFarm(_id);
    _updateUserRewardsDebt(_id, _user, _amount);

    Position storage position = positions[_id][_user];
    Farm storage farm = farms[_id];

    position.pointsAmount = position.pointsAmount + _amount;
    farm.totalPoints = farm.totalPoints + _amount;

    emit Boost(_id, _user, _amount);
  }


  /**
  * Unboost a farm position of esSteady, reducing multiplier for rewards
  * Callable only by the YieldBooster contract
  * @param _id  Unique id of farm
  * @param _user  Address of user farm position
  * @param _amount  Amount of esSteady points to unboost this position
  */
  function unboost(
    uint256 _id,
    address _user,
    uint256 _amount
  ) external nonReentrant whenNotPaused onlyYieldBooster {
    require(farms[_id].active, "Farm is not active");
    require(_user != address(0), "Invalid zero address");
    require(_amount > 0, "Cannot boost 0");

    claim(_id);

    _updateFarm(_id);
    _updateUserRewardsDebt(_id, _user, _amount);

    Position storage position = positions[_id][_user];
    Farm storage farm = farms[_id];

    position.pointsAmount = position.pointsAmount - _amount;
    farm.totalPoints = farm.totalPoints - _amount;

    emit Unboost(_id, _user, _amount);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
  * Create a new Farm
  * @param _active  Boolean for whether farm is active or not
  * @param _stakedToken Contract address for the staked tokens
  * @param _rewardsDistributionRate  Amount of rewards to be distributed per second
  * @param _esSteadySplit  % split of total rewards to be given in esSteady
  * @param _maxMultiplier  Max multiplier in 1e18
  * @param _endTime  Timestamp for when farm will end
  */
  function createFarm(
    bool _active,
    address _stakedToken,
    uint256 _rewardsDistributionRate,
    uint256 _esSteadySplit,
    uint256 _maxMultiplier,
    uint256 _endTime
  ) external onlyOwner {
    require(_stakedToken != address(0), "Invalid zero address");
    require(_rewardsDistributionRate > 0, "Rewards distribution rate must be greater than 0");
    require(_esSteadySplit <= MAX_REWARDS_SPLIT, "Reward split must be less than maximum");
    require(_maxMultiplier >= SAFE_MULTIPLIER, "Max multiplier must be greater than 1");
    require(_endTime > block.timestamp, "End time must be greater than current time");

    Farm memory farm = Farm({
      id: totalFarms,
      active: _active,
      stakedToken: _stakedToken,
      rewardsDistributionRate: _rewardsDistributionRate,
      esSteadySplit: _esSteadySplit,
      rewardsPerStakedToken: 0,
      lastUpdatedAt: block.timestamp,
      totalStaked: 0,
      totalPoints: 0,
      totalRewards: 0,
      maxMultiplier: _maxMultiplier,
      endTime: _endTime
    });

    farms[totalFarms] = farm;
    totalFarms += 1;
  }

  /**
  * Deposit more reward tokens to a farm
  * @param _id  Unique id of farm
  * @param _amount  Amount of reward tokens to deposit; in reward token's decimals
  */
  function depositRewardsTokens(uint256 _id, uint256 _amount) external nonReentrant onlyOwner {
    require(_id < totalFarms, "Cannot deposit to unexisting farm");
    require(_amount > 0, "Cannot deposit 0 amount");

    Farm storage farm = farms[_id];

    IERC20(steady).safeTransferFrom(msg.sender, address(this), _amount);
    farm.totalRewards += _amount;
  }

  /**
  * Deposit more reward tokens to a farm
  * @param _id  Unique id of farm
  * @param _amount  Amount of reward tokens to deposit; in reward token's decimals
  */
  function withdrawRewardsTokens(uint256 _id, uint256 _amount) external nonReentrant onlyOwner {
    Farm storage farm = farms[_id];

    require(_id < totalFarms, "Cannot withdraw from unexisting farm");
    require(_amount > 0, "Cannot withdraw 0 amount");
    require(
      farm.totalRewards > 0, "Cannot withdraw when farm has no reward tokens deposited"
    );
    require(
      _amount <= farm.totalRewards,
      "Cannot withdraw more reward tokens than deposited in farm"
    );

    IERC20(steady).safeTransfer(msg.sender, _amount);
    farm.totalRewards -= _amount;
  }

  /**
  * Update a farm's active status
  * @param _id  Unique id of farm
  * @param _active  Boolean to set farm to be active or not
  */
  function updateActive(uint256 _id, bool _active) external onlyOwner {
    farms[_id].active = _active;

    emit UpdateActive(_id, _active);
  }

  /**
  * Update the reward token distribution rate
  * @param _id  Unique id of farm
  * @param _rate  Rate of reward token distribution per second
  */
  function updateRewardsDistributionRate(uint256 _id, uint256 _rate) external onlyOwner {
    require(_rate >= 0, "Rate must be >= 0");

    farms[_id].rewardsDistributionRate = _rate;
    _updateFarm(_id);

    emit UpdateRewardsDistributionRate(_id, _rate);
  }

  /**
  * Update the rewards split % of total rewards to esSteady
  * @param _id  Unique id of farm
  * @param _esSteadySplit  Rewards split % of total rewards to esSteady
  */
  function updateEsSteadySplit(uint256 _id, uint256 _esSteadySplit) external onlyOwner {
    require(_esSteadySplit <= MAX_REWARDS_SPLIT, "Reward split must be less than maximum");

    farms[_id].esSteadySplit = _esSteadySplit;
    _updateFarm(_id);

    emit UpdateEsSteadySplit(_id, _esSteadySplit);
  }

  /**
  * Update the max multiplier of a farm
  * @param _id  Unique id of farm
  * @param _maxMultiplier  Rewards split % of total rewards to esSteady
  */
  function updateMaxMultiplier(uint256 _id, uint256 _maxMultiplier) external onlyOwner {
    require(_maxMultiplier >= SAFE_MULTIPLIER, "Max multiplier must be greater than 1");

    farms[_id].maxMultiplier = _maxMultiplier;
    _updateFarm(_id);

    emit UpdateMaxMultiplier(_id, _maxMultiplier);
  }

  /**
  * Update the end time of a farm
  * @param _id  Unique id of farm
  * @param _endTime  Timestamp of end time for farm
  */
  function updateEndTime(uint256 _id, uint256 _endTime) external onlyOwner {
    require(_endTime > block.timestamp, "End time must be greater than current time");

    farms[_id].endTime = _endTime;
    _updateFarm(_id);

    emit UpdateEndTime(_id, _endTime);
  }

  /**
  * Update yield booster plugin contract address
  * @param _yieldBooster  Address of yield booster contract
  */
  function updateYieldBooster(address _yieldBooster) external onlyOwner {
    yieldBooster = _yieldBooster;

    emit UpdateYieldBooster(msg.sender, block.timestamp);
  }

  /**
  * Update STEADY token manager contract address
  * @param _tokenManager  Address of token manager contract
  */
  function updateTokenManager(address _tokenManager) external onlyOwner {
    require(_tokenManager != address(0), "invalid zero address");

    tokenManager = _tokenManager;

    emit UpdateTokenManager(_tokenManager);
  }

  /**
  * Pause farms contract
  */
  function pause() external onlyOwner {
    _pause();
  }

  /**
  * Pause farms contract
  */
  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenManager {
  function usageAllocations(address userAddress, address usageAddress) external view returns (uint256 allocation);
  function allocateFromUsage(address userAddress, uint256 amount) external;
  function deallocateFromUsage(address userAddress, uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface IYieldBooster {
  function allocate(uint256 _amount) external;
  function deallocate(uint256 _amount) external;
  function getMultiplier(
    uint256 _stakedAmount,
    uint256 _totalStaked,
    uint256 _boostedPointsAmount,
    uint256 _totalBoostedPoints,
    uint256 _maxMultiplier
  ) external view returns (uint256);
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