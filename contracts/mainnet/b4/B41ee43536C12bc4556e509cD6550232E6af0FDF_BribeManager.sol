// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "SafeERC20.sol";
import "IVoter.sol";
import "IVeptp.sol";
import "ILockerV2.sol";
import "IMainStaking.sol";
import "IBaseRewardPool.sol";
import "IAvaxZapper.sol";
import "IBribe.sol";
import "IDelegateVotePool.sol";

/// @title Locker
/// @author Vector Team
contract BribeManager is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    IVoter public voter; // Platypus voter interface
    IVeptp public vePtp; // Platypus vePTP interface
    IMainStaking public mainStaking;

    address public locker; // VTX locker contract

    struct Pool {
        address poolAddress;
        address rewarder;
        bool isActive;
        string name;
    }

    address[] public pools;
    mapping(address => Pool) public poolInfos;

    mapping(address => uint256) public poolTotalVote;
    mapping(address => uint256) public userTotalVote;
    mapping(address => mapping(address => uint256)) public userVoteForPools; // unit = locked VTX

    mapping(address => address) public routePairAddresses;
    address public avaxZapper;
    uint256 public totalVtxInVote;
    uint256 constant DENOMINATOR = 10000;
    uint256 public lastCastTimer;
    uint256 public constant castVotesCooldown = 60;

    address public delegatedPool;

    event AddPool(address indexed lp, address indexed rewarder);

    event VoteReset(address indexed lp);

    event AllVoteReset();

    receive() external payable {}

    function setVoter(address _voter) external onlyOwner {
        voter = IVoter(_voter);
    }

    function setDelegatedPool(address _pool) external onlyOwner {
        delegatedPool = _pool;
    }

    function setAvaxZapper(address newZapper) external onlyOwner {
        avaxZapper = newZapper;
    }

    function getUserVoteForPools(address[] calldata lps, address _user)
        public
        view
        returns (uint256[] memory votes)
    {
        uint256 length = lps.length;
        votes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            votes[i] = userVoteForPools[_user][lps[i]];
        }
    }

    function getPoolsLength() external view returns (uint256) {
        return pools.length;
    }

    function lpTokenLength() public view returns (uint256) {
        return voter.lpTokenLength();
    }

    function getVoteForLp(address lp) public view returns (uint256) {
        return voter.getUserVotes(address(mainStaking), lp);
    }

    function getVoteForLps(address[] calldata lps) public view returns (uint256[] memory votes) {
        uint256 length = lps.length;
        votes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            votes[i] = getVoteForLp(lps[i]);
        }
    }

    function getLvtxVoteForPools(address[] calldata lps)
        public
        view
        returns (uint256[] memory lvtxVotes)
    {
        uint256 length = lps.length;
        lvtxVotes = new uint256[](length);
        for (uint256 i; i < length; i++) {
            lvtxVotes[i] = poolTotalVote[lps[i]];
        }
    }

    function usedVote() public view returns (uint256) {
        return vePtp.usedVote(address(mainStaking));
    }

    function totalVotes() public view returns (uint256) {
        return vePtp.balanceOf(address(mainStaking));
    }

    function remainingVotes() public view returns (uint256) {
        return totalVotes() - usedVote();
    }

    function addPool(
        address _lp,
        address _rewarder,
        string memory _name
    ) external onlyOwner {
        // it seems we have no way to check that the LP exists
        require(_lp != address(0), "ZERO ADDRESS");
        Pool memory pool = Pool({
            poolAddress: _lp,
            rewarder: _rewarder,
            isActive: true,
            name: _name
        });
        if (_lp != delegatedPool) {
            pools.push(_lp); // we don't want the delegatedPool in this array
        }
        poolInfos[_lp] = pool;
        emit AddPool(_lp, _rewarder);
    }

    /// @notice Changes the votes to zero for a platypus pool. Only internal.
    /// @param _lp address to reset
    function _resetVote(address _lp) internal {
        uint256 voteCount = getVoteForLp(_lp);

        if (voteCount > 0) {
            address[] memory lpToken = new address[](1);
            int256[] memory delta = new int256[](1);
            address[] memory rewarders = new address[](1);
            lpToken[0] = _lp;
            delta[0] = -int256(voteCount);
            rewarders[0] = poolInfos[_lp].rewarder;
            mainStaking.vote(lpToken, delta, rewarders, owner());
        }
        emit VoteReset(_lp);
    }

    /// @notice Changes the votes to zero for all platypus pools. Only internal.
    function _resetVotes() internal {
        uint256 length = pools.length;
        address[] memory _pools = new address[](length);
        int256[] memory votes = new int256[](length);
        address[] memory rewarders = new address[](length);
        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[pools[i]];
            uint256 currentVote = getVoteForLp(pool.poolAddress);
            if (currentVote > 0) {
                _pools[i] = pool.poolAddress;
                votes[i] = -int256(getVoteForLp(pool.poolAddress));
                rewarders[i] = pool.rewarder;
            }
        }
        mainStaking.vote(_pools, votes, rewarders, owner());
        emit AllVoteReset();
    }

    function isPoolActive(address pool) external view returns (bool) {
        return poolInfos[pool].isActive;
    }

    /// @notice Changes the votes to zero for all platypus pools. Only internal.
    /// @dev This would entirely kill all votings
    function clearPools() external onlyOwner {
        _resetVotes();
        uint256 length = pools.length;
        for (uint256 i; i < length; i++) {
            poolInfos[pools[i]].isActive = false;
        }
        delete pools;
    }

    function removePool(uint256 _index) external onlyOwner {
        uint256 length = pools.length;
        pools[_index] = pools[length - 1];
        pools.pop();
    }

    function veptpPerLockedVtx() public view returns (uint256) {
        if (ILockerV2(locker).totalSupply() == 0) return 0;
        return (totalVotes() * DENOMINATOR) / ILockerV2(locker).totalSupply();
    }

    function getUserLocked(address _user) public view returns (uint256) {
        return
            _user == delegatedPool
                ? poolTotalVote[delegatedPool]
                : ILockerV2(locker).balanceOf(_user);
    }

    /// @notice Vote on pools. Need to compute the delta prior to casting this.
    function vote(address[] calldata _lps, int256[] calldata _deltas) public {
        uint256 length = _lps.length;
        int256 totalUserVote;
        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[_lps[i]];
            require(pool.isActive, "Not active");
            int256 delta = _deltas[i];
            totalUserVote += delta;
            if (delta != 0) {
                if (delta > 0) {
                    poolTotalVote[pool.poolAddress] += uint256(delta);
                    userTotalVote[msg.sender] += uint256(delta);
                    userVoteForPools[msg.sender][pool.poolAddress] += uint256(delta);
                    IBaseRewardPool(pool.rewarder).stakeFor(msg.sender, uint256(delta)); // at that point, the delegatedPool will re enter the vote function. need to check for potential side effects
                } else {
                    poolTotalVote[pool.poolAddress] -= uint256(-delta);
                    userTotalVote[msg.sender] -= uint256(-delta);
                    userVoteForPools[msg.sender][pool.poolAddress] -= uint256(-delta);
                    IBaseRewardPool(pool.rewarder).withdrawFor(msg.sender, uint256(-delta), true);
                }
            }
        }
        if (msg.sender != delegatedPool) {
            // this already gets updated when a user vote for the delegated pool
            if (totalUserVote > 0) {
                totalVtxInVote += uint256(totalUserVote);
            } else {
                totalVtxInVote -= uint256(-totalUserVote);
            }
        }
        require(userTotalVote[msg.sender] <= getUserLocked(msg.sender), "Above vote limit");
    }

    /// @notice Unvote from an inactive pool. This makes it so that deleting a pool, or changing a rewarder doesn't block users from withdrawing
    function unvote(address _lp) public {
        Pool storage pool = poolInfos[_lp];
        uint256 currentVote = userVoteForPools[msg.sender][pool.poolAddress];
        require(!pool.isActive, "Active");
        poolTotalVote[pool.poolAddress] -= uint256(currentVote);
        userTotalVote[msg.sender] -= uint256(currentVote);
        userVoteForPools[msg.sender][pool.poolAddress] = 0;
        IBaseRewardPool(pool.rewarder).withdrawFor(msg.sender, uint256(currentVote), true);
    }

    /// @notice cast all pending votes
    /// @notice this  function will be gas intensive, hence a fee is given to the caller
    function castVotes(bool swapForAvax)
        public
        returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts)
    {
        require(block.timestamp - lastCastTimer > castVotesCooldown, "Last cast too recent");
        lastCastTimer = block.timestamp;
        uint256 length = pools.length;
        address[] memory _pools = new address[](length);
        int256[] memory votes = new int256[](length);
        address[] memory rewarders = new address[](length);
        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[pools[i]];
            _pools[i] = pool.poolAddress;
            rewarders[i] = pool.rewarder;

            uint256 currentVote = getVoteForLp(pool.poolAddress);
            uint256 targetVoteInLVTX = poolTotalVote[pool.poolAddress];
            uint256 targetVote = (targetVoteInLVTX * totalVotes()) / totalVtxInVote;
            if (targetVote >= currentVote) {
                votes[i] = int256(targetVote - currentVote);
            } else {
                votes[i] = int256(targetVote) - int256(currentVote);
            }
        }
        (address[] memory rewardTokens, uint256[] memory feeAmounts) = mainStaking.vote(
            _pools,
            votes,
            rewarders,
            msg.sender
        );
        if (swapForAvax) {
            finalFeeAmounts = new uint256[](1);
            finalFeeAmounts[0] = _swapFeesForAvax(rewardTokens, feeAmounts);
            finalRewardTokens = new address[](1);
            finalRewardTokens[0] = address(0);
        } else {
            _forwardRewards(rewardTokens, feeAmounts);
            finalRewardTokens = rewardTokens;
            finalFeeAmounts = feeAmounts;
        }
    }

    function _forwardRewards(address[] memory rewardTokens, uint256[] memory feeAmounts) internal {
        uint256 length = rewardTokens.length;
        for (uint256 i; i < length; i++) {
            if (rewardTokens[i] != address(0) && feeAmounts[i] > 0) {
                IERC20(rewardTokens[i]).safeTransfer(msg.sender, feeAmounts[i]);
            }
        }
    }

    function _swapFeesForAvax(address[] memory rewardTokens, uint256[] memory feeAmounts)
        internal
        returns (uint256 avaxAmount)
    {
        uint256 length = rewardTokens.length;
        for (uint256 i; i < length; i++) {
            if (rewardTokens[i] != address(0) && feeAmounts[i] > 0) {
                _approveTokenIfNeeded(rewardTokens[i], avaxZapper, feeAmounts[i]);
                avaxAmount += IAvaxZapper(avaxZapper).zapInToken(
                    rewardTokens[i],
                    feeAmounts[i],
                    msg.sender
                );
            }
        }
    }

    function _approveTokenIfNeeded(
        address token,
        address _to,
        uint256 _amount
    ) private {
        if (IERC20(token).allowance(address(this), _to) < _amount) {
            IERC20(token).approve(_to, type(uint256).max);
        }
    }

    /// @notice Cast a zero vote to harvest the bribes of selected pools
    /// @notice this  function has a lesser importance than casting votes, hence no rewards will be given to the caller.
    function harvestSinglePool(address[] calldata _lps) public {
        uint256 length = _lps.length;
        int256[] memory votes = new int256[](length);
        address[] memory rewarders = new address[](length);
        for (uint256 i; i < length; i++) {
            address lp = _lps[i];
            Pool storage pool = poolInfos[lp];
            rewarders[i] = pool.rewarder;
            votes[i] = 0;
        }
        mainStaking.vote(_lps, votes, rewarders, address(0));
    }

    /// @notice Cast all pending votes, this also harvest bribes from Platypus and distributes them to the pool rewarder.
    /// @notice This  function will be gas intensive, hence a fee is given to the caller
    function voteAndCast(
        address[] calldata _lps,
        int256[] calldata _deltas,
        bool swapForAvax
    ) external returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts) {
        vote(_lps, _deltas);
        (finalRewardTokens, finalFeeAmounts) = castVotes(swapForAvax);
    }

    /// @notice Harvests user rewards for each pool
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    function harvestBribe(address[] calldata lps) public {
        _harvestBribeFor(lps, msg.sender);
    }

    /// @notice Harvests user rewards for each pool
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    function harvestBribeFor(address[] calldata lps, address _for) public {
        _harvestBribeFor(lps, _for);
    }

    /// @notice Harvests user rewards for each pool
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    function _harvestBribeFor(address[] calldata lps, address _for) internal {
        uint256 length = lps.length;
        for (uint256 i; i < length; i++) {
            if (lps[i] == delegatedPool) {
                IDelegateVotePool(delegatedPool).getReward(_for);
            } else {
                IBaseRewardPool(poolInfos[lps[i]].rewarder).getReward(_for);
            }
        }
    }

    /// @notice Harvests user rewards for each pool where he has voted
    /// @notice If bribes weren't harvested, this might be lower than actual current value
    /// @param _for user to harvest bribes for.
    function harvestAllBribes(address _for)
        public
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards)
    {
        address[] memory delegatePoolRewardTokens;
        uint256[] memory delegatePoolRewardAmounts;
        if (userVoteForPools[_for][delegatedPool] > 0) {
            (delegatePoolRewardTokens, delegatePoolRewardAmounts) = IDelegateVotePool(delegatedPool)
                .getReward(_for);
        }
        uint256 delegatePoolRewardsLength = delegatePoolRewardTokens.length;
        uint256 length = pools.length;
        rewardTokens = new address[](length + delegatePoolRewardsLength);
        earnedRewards = new uint256[](length + delegatePoolRewardsLength);
        for (uint256 i; i < length; i++) {
            Pool storage pool = poolInfos[pools[i]];
            address lp = pool.poolAddress;
            address bribesContract = voter.bribes(lp);
            if (bribesContract != address(0)) {
                rewardTokens[i] = address(IBribe(bribesContract).rewardToken());
                if (userVoteForPools[_for][lp] > 0) {
                    earnedRewards[i] = IBaseRewardPool(pool.rewarder).earned(_for, rewardTokens[i]);
                    IBaseRewardPool(pool.rewarder).getReward(_for);
                }
            }
        }
        for (uint256 i = length; i < length + delegatePoolRewardsLength; i++) {
            rewardTokens[i] = delegatePoolRewardTokens[i - length];
            earnedRewards[i] = delegatePoolRewardAmounts[i - length];
        }
    }

    /// @notice Cast all votes to platypus, harvesting the rewards from platypus for Vector, and then harvesting specifically for the chosen pools.
    /// @notice this  function will be gas intensive, hence a fee is given to the caller for casting the vote.
    /// @param lps lps to harvest
    function castVotesAndHarvestBribes(address[] calldata lps, bool swapForAvax) external {
        castVotes(swapForAvax);
        harvestBribe(lps);
    }

    function previewAvaxAmountForHarvest(address[] calldata _lps) external view returns (uint256) {
        (address[] memory rewardTokens, uint256[] memory amounts) = mainStaking
            .pendingBribeCallerFee(_lps);
        return IAvaxZapper(avaxZapper).previewTotalAmount(rewardTokens, amounts);
    }

    /// @notice Returns pending bribes
    function previewBribes(
        address lp,
        address[] calldata inputRewardTokens,
        address _for
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts) {
        uint256 length = inputRewardTokens.length;
        Pool storage pool = poolInfos[lp];
        rewardTokens = new address[](length);
        amounts = new uint256[](length);
        for (uint256 index; index < length; ++index) {
            if (IBaseRewardPool(pool.rewarder).isRewardToken(inputRewardTokens[index])) {
                rewardTokens[index] = inputRewardTokens[index];
                uint256 amount = IBaseRewardPool(pool.rewarder).earned(_for, rewardTokens[index]);
                amounts[index] = amount;
            } else {
                rewardTokens[index] = inputRewardTokens[index];
                amounts[index] = 0;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVoter {
    function add(
        address _gauge,
        address _lpToken,
        address _bribe
    ) external;

    function bribes(address) external view returns (address);

    function claimBribes(address[] calldata _lpTokens)
        external
        returns (uint256[] memory bribeRewards);

    function distribute(address _lpToken) external;

    function emergencyPtpWithdraw() external;

    function getUserVotes(address _user, address _lpToken) external view returns (uint256);

    function index() external view returns (uint128);

    function initialize(
        address _ptp,
        address _vePtp,
        uint88 _ptpPerSec,
        uint256 _startTimestamp
    ) external;

    function lastRewardTimestamp() external view returns (uint40);

    function lpTokenLength() external view returns (uint256);

    function lpTokens(uint256) external view returns (address);

    function owner() external view returns (address);

    function pause(address _lpToken) external;

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[] memory bribeRewards);

    function pendingPtp(address _lpToken) external view returns (uint256);

    function ptp() external view returns (address);

    function ptpPerSec() external view returns (uint88);

    function renounceOwnership() external;

    function resume(address _lpToken) external;

    function setBribe(address _lpToken, address _bribe) external;

    function setGauge(address _lpToken, address _gauge) external;

    function setPtpPerSec(uint88 _ptpPerSec) external;

    function totalWeight() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function vePtp() external view returns (address);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[] memory bribeRewards);

    function votes(address, address) external view returns (uint256);

    function weights(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVeptp {
    function usedVote(address _user) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILockerV2 {
    struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 unlockingStrategy;
        uint256 alreadyUnstaked;
        uint256 alreadyWithdrawn;
    }

    function DENOMINATOR() external view returns (uint256);

    function VTX() external view returns (address);

    function __LockerV2_init_(
        address _masterchief,
        uint256 _maxSlots,
        address _previousLocker,
        address _rewarder,
        address _stakingToken
    ) external;

    function addNewStrategy(
        uint256 _lockTime,
        uint256 _rewardPercent,
        uint256 _forfeitPercent,
        uint256 _instantUnstakePercent,
        bool _isLinear
    ) external;

    function addToUnlock(uint256 amount, uint256 slotIndex) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function cancelUnlock(uint256 slotIndex) external;

    function claim()
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function claimFor(address _for)
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount) external;

    function depositFor(address _for, uint256 _amount) external;

    function getAllUserUnlocking(address _user)
        external
        view
        returns (UserUnlocking[] memory slots);

    function getUserNthSlot(address _user, uint256 n)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );

    function getUserRewardPercentage(address _user)
        external
        view
        returns (uint256 rewardPercentage);

    function getUserSlotLength(address _user) external view returns (uint256);

    function getUserTotalDeposit(address _user) external view returns (uint256);

    function harvest() external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function masterchief() external view returns (address);

    function maxSlot() external view returns (uint256);

    function migrate(address user, bool[] calldata onlyDeposit) external;

    function migrateFor(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external;

    function migrated(address) external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function previousLocker() external view returns (address);

    function renounceOwnership() external;

    function rewarder() external view returns (address);

    function setBribeManager(address _address) external;

    function setMaxSlots(uint256 _maxDeposits) external;

    function setPreviousLocker(address _locker) external;

    function setStrategyStatus(uint256 strategyIndex, bool status) external;

    function setWhitelistForTransfer(address _for, bool status) external;

    function stakeInMasterChief() external;

    function stakingToken() external view returns (address);

    function startUnlock(
        uint256 strategyIndex,
        uint256 amount,
        uint256 slotIndex
    ) external;

    function symbol() external view returns (string memory);

    function totalLocked() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalUnlocking() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWhitelist(address) external view returns (bool);

    function unlock(uint256 slotIndex) external;

    function unlockingStrategies(uint256)
        external
        view
        returns (
            uint256 unlockTime,
            uint256 forfeitPercent,
            uint256 rewardPercent,
            uint256 instantUnstakePercent,
            bool isLinear,
            bool isActive
        );

    function unpause() external;

    function userUnlocking(address) external view returns (uint256);

    function userUnlockings(address, uint256)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMainStaking {
    function CALLER_FEE() external view returns (uint256);

    function MAX_CALLER_FEE() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function WAVAX() external view returns (address);

    function addBonusRewardForAsset(address _asset, address _bonusToken) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isPTP,
        bool isAddress
    ) external;

    function assetToBonusRewards(address, uint256) external view returns (address);

    function bribeCallerFee() external view returns (uint256);

    function bribeFeeCollector() external view returns (address);

    function bribeManager() external view returns (address);

    function bribeProtocolFee() external view returns (uint256);

    function claimVePTP() external;

    function computeAPR() external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address sender
    ) external;

    function depositWithDifferentAsset(
        address token,
        address asset,
        uint256 amount,
        address sender
    ) external;

    function feeInfos(uint256)
        external
        view
        returns (
            uint256 max_value,
            uint256 min_value,
            uint256 value,
            address to,
            bool isPTP,
            bool isAddress,
            bool isActive
        );

    function getDepositTokensForShares(uint256 amount, address token)
        external
        view
        returns (uint256);

    function getLPTokensForShares(uint256 amount, address token) external view returns (uint256);

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lp,
            uint256 sizeLp,
            address receipt,
            uint256 size,
            address rewards_addr,
            address helper
        );

    function getSharesForDepositTokens(uint256 amount, address token)
        external
        view
        returns (uint256);

    function harvest(address token, bool isUser) external;

    function masterPlatypus() external view returns (address);

    function masterVtx() external view returns (address);

    function multiHarvest(address token, bool isUser) external;

    function owner() external view returns (address);

    function pendingBribeCallerFee(address[] calldata pendingPools)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory callerFeeAmount);

    function percentPTPStored() external view returns (uint256);

    function pools(address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lpAddress,
            uint256 sizeLp,
            uint256 size,
            address receiptToken,
            address rewarder,
            address helper
        );

    function ptp() external view returns (address);

    function ptpMigration(uint256[] calldata _pids) external;

    function registerPool(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _staking,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external;

    function registerPoolWithDifferentAsset(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _assetToken,
        address _staking,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external returns (address, address);

    function removeFee(uint256 index) external;

    function removePool(address token) external;

    function renounceOwnership() external;

    function sendTokenRewards(address _token, address _rewarder) external;

    function setBribeCallerFee(uint256 newValue) external;

    function setBribeFeeCollector(address _collector) external;

    function setBribeManager(address _manager) external;

    function setBribeProtocolFee(uint256 newValue) external;

    function setCallerFee(uint256 value) external;

    function setFee(uint256 index, uint256 value) external;

    function setFeeRecipient(
        uint256 index,
        address _to,
        bool _isPtp,
        bool _isAddress
    ) external;

    function setMasterPlatypus(address _masterPtp) external;

    function setPoolHelper(address token, address _poolhelper) external;

    function setPoolToken(address _token, address pool) external;

    function setSmartConvertor(address _smartConvertor) external;

    function setVoter(address _voter) external;

    function smartConvertor() external view returns (address);

    function stakePTP(uint256 amount) external;

    function stakingStable() external view returns (address);

    function staking_ptp() external view returns (address);

    function storagePTP() external view returns (address);

    function tokenToAvaxPool(address) external view returns (address);

    function tokenToPool(address) external view returns (address);

    function totalFee() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    ) external returns (address[] memory rewardTokens, uint256[] memory feeAmounts);

    function voter() external view returns (address);

    function withdraw(
        address token,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function withdrawLP(
        address token,
        uint256 _amount,
        address sender
    ) external;

    function withdrawWithDifferentAsset(
        address token,
        address asset,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function xPTP() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBaseRewardPool {
    function balanceOf(address _account) external view returns (uint256);

    function donateRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function getReward(address _account) external returns (bool);

    function getRewardUser() external returns (bool);

    function getStakingToken() external view returns (address);

    function isRewardToken(address) external view returns (bool);

    function mainRewardToken() external view returns (address);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function renounceOwnership() external;

    function rewardDecimals(address _rewardToken) external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingDecimals() external view returns (uint256);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateFor(address _account) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAvaxZapper {
    function ROUTER() external view returns (address);

    function WAVAX() external view returns (address);

    function joeFactory() external view returns (address);

    function owner() external view returns (address);

    function previewAmount(address _from, uint256 amount) external view returns (uint256);

    function previewTotalAmount(address[] calldata inTokens, uint256[] calldata amounts)
        external
        view
        returns (uint256 avaxAmount);

    function removeToken(uint256 i) external;

    function renounceOwnership() external;

    function routePair(address _address) external view returns (address);

    function routePairAddresses(address) external view returns (address);

    function setRoutePairAddress(address asset, address route) external;

    function sweep() external;

    function tokens(uint256) external view returns (address);

    function transferOwnership(address newOwner) external;

    function withdraw(address token) external;

    function zapInToken(
        address _from,
        uint256 amount,
        address receiver
    ) external returns (uint256 avaxAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBribe {
    function balance() external view returns (uint256);

    function emergencyWithdraw() external;

    function isNative() external view returns (bool);

    function lpToken() external view returns (address);

    function onVote(
        address _user,
        uint256 _lpAmount,
        uint256 originalTotalVotes
    ) external returns (uint256);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function pendingTokens(address _user) external view returns (uint256 pending);

    function poolInfo()
        external
        view
        returns (uint128 accTokenPerShare, uint48 lastRewardTimestamp);

    function renounceOwnership() external;

    function rewardToken() external view returns (address);

    function setOperator(address _operator) external;

    function setRewardRate(uint256 _tokenPerSec) external;

    function tokenPerSec() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool() external;

    function userInfo(address)
        external
        view
        returns (
            uint128 amount,
            uint128 rewardDebt,
            uint256 unpaidRewards
        );

    function voter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDelegateVotePool {
    function DENOMINATOR() external view returns (uint256);

    function LVTX() external view returns (address);

    function __DelegateVotePool_init_(address _LVTX, address _bribeManager) external;

    function balanceOf(address _account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function castVotes() external;

    function claimManually() external;

    function currentVotes(address) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function donateRewards(uint256 _amountReward, address _rewardToken) external;

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function feeCollector() external view returns (address);

    function getPendingRewards(address user)
        external
        view
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getRewardUser()
        external
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getReward(address _for)
        external
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function harvestAndGetRewards() external;

    function isRewardToken(address) external view returns (bool);

    function isvotePool(address) external view returns (bool);

    function lengthOfRewards() external view returns (uint256);

    function locker() external view returns (address);

    function mainRewardToken() external view returns (address);

    function owner() external view returns (address);

    function protocolFee() external view returns (uint256);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external;

    function renounceOwnership() external;

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function setProtocolFee(uint256 fee) external;

    function setProtocolFeeCollector(address collector) external;

    function setVotingLock(uint256 _startTime, uint256 _totalTime) external;

    function stakingDecimals() external view returns (uint256);

    function startTime() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unlockTime() external view returns (uint256);

    function updateFor(address _account) external;

    function updateVote() external;

    function updateWeight(address lp, uint256 weight) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function votePools(uint256) external view returns (address);

    function votingWeights(address) external view returns (uint256);

    function withdraw(uint256 _amount, bool _claim) external;
}