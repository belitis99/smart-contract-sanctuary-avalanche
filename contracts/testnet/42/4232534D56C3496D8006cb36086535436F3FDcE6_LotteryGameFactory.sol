// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "../interfaces/ILotteryGameFactory.sol";
import "../interfaces/IRewardDistribution.sol";
import "../governance/interfaces/IGovernance.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "../router/Router.sol";
import "../Constants.sol";

interface IGenerateBytecode{
    function createLotteryBytecode() external returns(bytes memory);
}

/// @title LotteryGameFactory contract
/// @author Applicature
/// @dev Contract for for new games managing: creating, deleting and entering multiple games at one transaction
/// the owner should be governance (Executor contract)
contract LotteryGameFactory is ILotteryGameFactory, Ownable {
    using SafeERC20 for IERC20;
    /// @notice info about created lotteries addresses
    address[] public lotteryGames;
    /// @notice store autorized games and its id
    mapping(address => LotteryGameInfo) public autorizedLotteryGames;
    /// @notice point on the max available limit for number of games that can be entered in one transaction
    uint256 public loopLimit;
    /// @notice Router contract address
    Router public router;
    /// @notice RewardDistribution contract address
    IRewardDistribution public rewardDistribution;
    /// @notice GameToken contract address
    IERC20 public immutable gameToken;
    /// @notice LINK token address
    LinkTokenInterface public immutable linkToken;
    /// @notice Governance contract address
    IGovernance private immutable governance;
    /// @dev count of created game in total
    uint256 private lotteryCount;
    IGenerateBytecode public generateBytecode;

    modifier isLoopLimitPassed(uint256 gamesListLengh) {
        if (gamesListLengh <= loopLimit) {
            _;
        }
    }

    constructor(
        address gameToken_,
        address rewardDistribution_,
        address governance_,
        address router_,
        address generateBytecode_
    ) {
        require(
            gameToken_ != address(0) &&
                governance_ != address(0) &&
                router_ != address(0) &&
                generateBytecode_ != address(0),
            "ZERO_ADDRESS"
        );
        gameToken = IERC20(gameToken_);
        rewardDistribution = IRewardDistribution(rewardDistribution_);
        governance = IGovernance(governance_);
        router = Router(router_);
        linkToken = LinkTokenInterface(LINK_TOKEN);
        generateBytecode = IGenerateBytecode(generateBytecode_);
    }

    /**
     * @dev setting address to rewardDistributed contract
     * @param rewardDistribution_ address of RewardDistribution contract
     */
    function setRewardDistribution(address rewardDistribution_)
        external
        onlyOwner
    {
        require(rewardDistribution_ != address(0), "ZERO_ADDRESS");
        rewardDistribution = IRewardDistribution(rewardDistribution_);
    }

    /// @notice setting limit for number of games that can be entered in one transaction
    /// @param loopLimit_ point on the max available limit for number of games
    function setLoopLimit(uint256 loopLimit_) external onlyOwner {
        require(loopLimit_ > 0, "INVALID_VALUE");
        loopLimit = loopLimit_;
    }

    /// @notice creating new instance of CustomLotteryGame contract
    /// @param constructorParam constructors encoded params ofCustomLotteryGame contract
    /// @param timelock_ new lottery timelock for unlocking rounds
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    function createLottery(
        bytes calldata constructorParam,
        ICustomLotteryGame.TimelockInfo memory timelock_,
        string memory name,
        bytes memory encryptedEmail,
        uint32 gasLimit,
        bytes memory checkData,
        uint96 amount,
        uint8 source
    ) external override onlyOwner returns (address) {
        
        bytes memory bytecode = abi.encodePacked(generateBytecode.createLotteryBytecode(), constructorParam); 

        bytes32 salt = keccak256(abi.encodePacked(name, lotteryCount));
        // create CustomLotteryGame instance
        address lotteryGameAddress = Create2.deploy(0, salt, bytecode);
        
        lotteryCount++;

        lotteryGames.push(lotteryGameAddress);
        autorizedLotteryGames[lotteryGameAddress].isAuthorized = true;
        autorizedLotteryGames[lotteryGameAddress].gameId =
            lotteryGames.length -
            1;

        emit CreatedLottery(
            lotteryGameAddress
        );

        require(amount >= MIN_LINK * DECIMALS, "INVALID_VALUE");

        linkToken.transferFrom(msg.sender, address(router), amount);


        // add additional lottery to the router
        router.registerAdditionalLottery(
            name,
            encryptedEmail,
            gasLimit,
            checkData,
            amount,
            source,
            lotteryGameAddress
        );

        ICustomLotteryGame(lotteryGameAddress).setTimelock(timelock_);
        // authorized in the RewardDistibution contract
        rewardDistribution.addNewGame(lotteryGameAddress);
        return lotteryGameAddress;
    }

    /// @notice deleting lottery game (the game is invalid)
    /// @param game address of the required game to delete
    function deleteLottery(address game) external override onlyOwner {
        require(autorizedLotteryGames[game].isAuthorized, "INVALID_ADDRESS");

        // delete CustomLotteryGame instance
        address updatedAddress = lotteryGames[lotteryGames.length - 1];
        autorizedLotteryGames[updatedAddress].gameId = autorizedLotteryGames[
            game
        ].gameId;
        lotteryGames[autorizedLotteryGames[game].gameId] = updatedAddress;
        delete autorizedLotteryGames[game];
        lotteryGames.pop();

        emit DeletedLottery(game);

        // cancel upkeep registration
        router.cancelSubscription(game);

        // deteted from the RewardDistibution contract
        rewardDistribution.removeGame(game);
    }

    /// @notice allow the user to enter in a few additional games at one transaction
    /// @dev all games should be approve first, using approveForMultipleGames() for it
    /// @param gamesList list of games addresses
    function entryMultipleGames(address[] memory gamesList)
        external
        override
        isLoopLimitPassed(gamesList.length)
    {
        require(gamesList.length != 0, "INCORRECT_LENGTH");

        for (uint256 i = 0; i < gamesList.length; i++) {
            address gameAddress = gamesList[i];
            require(
                autorizedLotteryGames[gameAddress].isAuthorized,
                "LotteryGameFactor: game address is not registered"
            );

            gameToken.safeTransferFrom(
                msg.sender,
                address(this),
                ICustomLotteryGame(gameAddress).getParticipationFee()
            );

            ICustomLotteryGame(gameAddress).entryGame(msg.sender);
        }
    }

    /// @notice approve of game tokens for selected games at one transaction
    /// @param gamesList list of games addresses
    function approveForMultipleGames(address[] memory gamesList)
        external
        override
        isLoopLimitPassed(gamesList.length)
    {
        require(
            gamesList.length != 0,
            "LotteryGameFactor: games list is empty"
        );

        for (uint256 i = 0; i < gamesList.length; i++) {
            address gameAddress = gamesList[i];
            if (
                type(uint256).max !=
                gameToken.allowance(address(this), gameAddress)
            ) {
                gameToken.approve(gameAddress, type(uint256).max);
            }
        }
    }

    /**
     * @dev Getter of the all additional lotteries
     * @return array of all additional lotteries
     **/
    function getCustomLotteries() external view returns (address[] memory) {
        return lotteryGames;
    }

    function setGenerateBytecode(address generateBytecode_) external onlyOwner{
        generateBytecode = IGenerateBytecode(generateBytecode_);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./ICustomLotteryGame.sol";

/// @title Define interface for LotteryGameFactory contract
interface ILotteryGameFactory {
    /// @dev store info about status of lottery game (autorized or not)
    /// @param isAuthorized true if lottery game is created
    /// @param gameId lottery game id
    struct LotteryGameInfo {
        bool isAuthorized;
        uint256 gameId;
    }

    /// @dev emitted when a game is created
    /// @param lottery address of the new lottery contract
    event CreatedLottery(
        address lottery
    );

    /// @dev emitted when a game is deleted
    /// @param deletedGameAddress address of the deleted game
    event DeletedLottery(address indexed deletedGameAddress);

    /// @notice creating new instance of CustomLotteryGame contract
    
    /// param game struct of info about the game
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    function createLottery(
        bytes calldata constructorParam,
        ICustomLotteryGame.TimelockInfo memory timelock_,
        string memory name,
        bytes memory encryptedEmail,
        uint32 gasLimit,
        bytes memory checkData,
        uint96 amount,
        uint8 source
    ) external returns (address);

    /// @dev deleting lottery game (the game is invalid)
    /// @param game address of the required game to delete
    function deleteLottery(address game) external;

    /// @dev allow the user to enter in a few additional games at one transaction
    /// @param gamesList list of games addresses
    function entryMultipleGames(address[] memory gamesList)
        external;

    /// @dev approve of game tokens for selected games at one transaction
    /// @param gamesList list of games addresses
    function approveForMultipleGames(address[] memory gamesList)
        external;
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

interface IRewardDistribution {
    /// @notice rewards types
    enum RewardTypes {
        COMMUNITY,
        GOVERNANCE
    }

    /// @notice Info needed to store community reward distribution
    struct CommunityReward {
        uint256 timeOfGameFinish;
        uint256 countOfHolders;
        uint256 totalUsersHoldings;
        uint256 amountForDistribution;
        bool isMainLottoToken;
    }

    /// @notice Voting power info
    struct VotingPowerInfo {
        uint256 lottoPower;
        uint256 gamePower;
        bool isUpdated;
    }

    /// @notice Info about last distribution index
    struct LastProposalIndexInfo {
        uint256 index;
        // need this to handle case when the prev index will be 0 and count of proposals will be 1
        uint256 prevCountOfProposals;
    }

    /// @notice Info about indexes of valid proposals for the governance reward distribution
    struct GovRewardIndexes {
        uint256 from;
        uint256 to;
    }

    /// @notice Info about indexes of valid proposals for the governance reward distribution
    struct ClaimedIndexes {
        uint256 communityReward;
        uint256 governanceReward;
        bool isCommNullIndexUsed;
        bool isGovNullIndexUsed;
    }

    /// @notice Info needed to store governance reward distribution
    struct GovernanceReward {
        uint256 startPeriod;
        uint256 endPeriod;
        uint256 totalLottoAmount;
        uint256 totalGameAmount;
        uint256 lottoPerProposal;
        uint256 gamePerProposal;
        uint256 totalUsersHoldings;
        uint256 countOfProposals;
        GovRewardIndexes validPropIndexes;
    }

    /// @param interval point interval needed within checks e.g. 7 days
    /// @param day day of the week (0(Sunday) - 6(Saturday))
    struct CheckGovParams {
        uint256 interval;
        uint8 day;
    }

    /// @notice Emit when new lottery game is added
    /// @param lotteryGame address of lotteryGame contract
    event LotteryGameAdded(address indexed lotteryGame);

    /// @notice Emit when new lottery game is removed
    /// @param lotteryGame address of lotteryGame contract
    event LotteryGameRemoved(address indexed lotteryGame);

    /// @notice Emit when new reward distribution is added
    /// @param fromGame address of lotteryGame contract who added a distribution
    /// @param rewardType type of reward
    /// @param amountForDistribution amount of tokens for distribution
    event RewardDistributionAdded(
        address indexed fromGame,
        RewardTypes rewardType,
        uint256 amountForDistribution
    );

    /// @notice Emit when new reward distribution is added
    /// @param user address of user who claim the tokens
    /// @param distributedToken address of token what is claimed
    /// @param amount amount of tokens are claimed
    event RewardClaimed(
        address indexed user,
        address indexed distributedToken,
        uint256 indexed amount
    );

    /// @notice Add new game to the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of new game contract
    function addNewGame(address game_) external;

    /// @notice Remove registrated game from the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of game to be removed
    function removeGame(address game_) external;

    /// @notice Add new community reward distribution portion
    /// @dev Allowed to be called only by authorized game contracts
    /// @param distributionInfo structure of <CommunityReward> type
    function addDistribution(CommunityReward calldata distributionInfo)
        external;

    /// @notice Claim available community reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimCommunityReward() external;

    /// @notice Claim available reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimGovernanceReward() external;

    /// @notice Return available community reward of user
    /// @param user address need check rewards for
    function availableCommunityReward(address user)
        external
        view
        returns (uint256 lottoRewards, uint256 gameRewards);

    /// @notice Return available community reward of user
    /// @param user address need check rewards for
    function availableGovernanceReward(address user)
        external
        view
        returns (uint256 lottoRewards, uint256 gameRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IExecutor.sol";

interface IGovernance {
    /**
     * @dev List of available states of proposal
     * @param Pending When the proposal is creted and the votingDelay is not passed
     * @param Canceled When the proposal is calceled
     * @param   Active When the proposal is on voting
     * @param  Failed Whnen the proposal is not passes the quorum
     * @param  Succeeded When the proposal is passed
     * @param   Expired When the proposal is expired (the execution period passed)
     * @param  Executed When the proposal is executed
     **/
    enum ProposalState {
        Pending,
        Canceled,
        Active,
        Failed,
        Succeeded,
        Expired,
        Executed
    }

    /**
     * @dev Struct of a votes
     * @param support is the user suport proposal or not
     * @param votingPower amount of voting  power
     * @param submitTimestamp date when vote was submitted
     **/
    struct Vote {
        bool support;
        uint248 votingPower;
        uint256 submitTimestamp;
    }

    /**
     * @dev Struct of a proposal with votes
     * @param id Id of the proposal
     * @param creator Creator address
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block.timestamp when the proposal was started
     * @param endTimestamp block.timestamp when the proposal will ended
     * @param executionTime block.timestamp of the minimum time when the propsal can be execution, if set 0 it can't be executed yet
     * @param forVotes amount of For votes
     * @param againstVotes amount of Against votes
     * @param executed true is proposal is executes, false if proposal is not executed
     * @param canceled true is proposal is canceled, false if proposal is not canceled
     * @param strategy the address of governanceStrategy contract for current proposal voting power calculation
     * @param ipfsHash IPFS hash of the proposal
     * @param lottoVotes lotto tokens voting power portion
     * @param gameVotes game tokens voting power portion
     * @param votes the Vote struct where is hold mapping of users who voted for the proposal
     * @param voters the array of users addresses who voted for or against for the proposal
     **/
    struct Proposal {
        uint256 id;
        address creator;
        IExecutor executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        string ipfsHash;
        uint256 lottoVotes;
        uint256 gameVotes;
        mapping(address => Vote) votes;
        address[] voters;
    }

    /**
     * @dev Struct of a proposal without votes
     * @param id Id of the proposal
     * @param creator Creator address
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block.timestamp when the proposal was started
     * @param endTimestamp block.timestamp when the proposal will ended
     * @param executionTime block.timestamp of the minimum time when the propsal can be execution, if set 0 it can't be executed yet
     * @param forVotes amount of For votes
     * @param againstVotes amount of Against votes
     * @param executed true is proposal is executes, false if proposal is not executed
     * @param canceled true is proposal is canceled, false if proposal is not canceled
     * @param strategy the address of governanceStrategy contract for current proposal voting power calculation
     * @param ipfsHash IPFS hash of the proposal
     * @param lottoVotes lotto tokens voting power portion
     * @param gameVotes game tokens voting power portion
     **/
    struct ProposalWithoutVotes {
        uint256 id;
        address creator;
        IExecutor executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        string ipfsHash;
        uint256 lottoVotes;
        uint256 gameVotes;
    }

    /**
     * @notice Struct for create proposal
     * @param targets - list of contracts called by proposal's associated transactions
     * @param values - list of value in wei for each propoposal's associated transaction
     * @param signatures - list of function signatures (can be empty) to be used when created the callData
     * @param calldatas - list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param ipfsHash - IPFS hash of the proposal
     */
    struct CreatingProposal {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        string ipfsHash;
    }

    /**
     * @dev emitted when a new proposal is created
     * @param id Id of the proposal
     * @param creator address of the creator
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block number when vote starts
     * @param endTimestamp block number when vote ends
     * @param strategy address of the governanceStrategy contract
     * @param ipfsHash IPFS hash of the proposal
     **/
    event ProposalCreated(
        uint256 id,
        address indexed creator,
        IExecutor indexed executor,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 executionTimestamp,
        address strategy,
        string ipfsHash
    );

    /**
     * @dev emitted when a proposal is canceled
     * @param id Id of the proposal
     **/
    event ProposalCanceled(uint256 id);

    /**
     * @dev emitted when a proposal is executed
     * @param id Id of the proposal
     * @param initiatorExecution address of the initiator of the execution transaction
     **/
    event ProposalExecuted(uint256 id, address indexed initiatorExecution);
    /**
     * @dev emitted when a vote is registered
     * @param id Id of the proposal
     * @param voter address of the voter
     * @param support boolean, true = vote for, false = vote against
     * @param votingPower Power of the voter/vote
     **/
    event VoteEmitted(
        uint256 id,
        address indexed voter,
        bool support,
        uint256 votingPower
    );

    /**
     * @dev emitted when a new governance strategy set
     * @param newStrategy address of new strategy
     * @param initiatorChange msg.sender address
     **/
    event GovernanceStrategyChanged(
        address indexed newStrategy,
        address indexed initiatorChange
    );

    /**
     * @dev emitted when a votingDelay is changed
     * @param newVotingDelay new voting delay in seconds
     * @param initiatorChange msg.sender address
     **/
    event VotingDelayChanged(
        uint256 newVotingDelay,
        address indexed initiatorChange
    );

    /**
     * @dev emitted when a executor is authorized
     * @param executor new address of executor
     **/
    event ExecutorAuthorized(address executor);
    /**
     * @dev emitted when a executor is unauthorized
     * @param executor  address of executor
     **/
    event ExecutorUnauthorized(address executor);

    /**
     * @dev emitted when a community reward percent is changed
     * @param communityReward  percent of community reward
     **/
    event CommunityRewardChanged(uint256 communityReward);

    /**
     * @dev emitted when a governance reward percent is changed
     * @param governanceReward  percent of governance reward
     **/
    event GovernanceRewardChanged(uint256 governanceReward);

    /**
     * @dev Creates a Proposal (needs Voting Power of creator > propositionThreshold)
     * @param executor - The Executor contract that will execute the proposal
     * @param targets - list of contracts called by proposal's associated transactions
     * @param values - list of value in wei for each propoposal's associated transaction
     * @param signatures - list of function signatures (can be empty) to be used when created the callData
     * @param calldatas - list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param ipfsHash - IPFS hash of the proposal
     **/
    function createProposal(
        IExecutor executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory ipfsHash
    ) external returns (uint256);

    /**
     * @dev Cancels a Proposal,
     * either at anytime by guardian
     * or when proposal is Pending/Active and threshold of creator no longer reached
     * @param proposalId id of the proposal
     **/
    function cancelProposal(uint256 proposalId) external;

    /**
     * @dev Execute the proposal (If Proposal Succeeded)
     * @param proposalId id of the proposal to execute
     **/
    function executeProposal(uint256 proposalId) external payable;

    /**
     * @dev Function allowing msg.sender to vote for/against a proposal
     * @param proposalId id of the proposal
     * @param support boolean, true = vote for, false = vote against
     **/
    function submitVote(uint256 proposalId, bool support) external;

    /**
     * @dev Set new GovernanceStrategy
     * @notice owner should be a  executor, so needs to make a proposal
     * @param governanceStrategy new Address of the GovernanceStrategy contract
     **/
    function setGovernanceStrategy(address governanceStrategy) external;

    /**
     * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
     * @notice owner should be a  executor, so needs to make a proposal
     * @param votingDelay new voting delay in seconds
     **/
    function setVotingDelay(uint256 votingDelay) external;

    /**
     * @dev Add new addresses to the list of authorized executors
     * @notice owner should be a  executor, so needs to make a proposal
     * @param executors list of new addresses to be authorized executors
     **/
    function authorizeExecutors(address[] calldata executors) external;

    /**
     * @dev Remove addresses from the list of authorized executors
     * @notice owner should be a  executor, so needs to make a proposal
     * @param executors list of addresses to be removed as authorized executors
     **/
    function unauthorizeExecutors(address[] calldata executors) external;

    /**
     * @dev Let the guardian abdicate from its priviledged rights.Set _guardian address as zero address
     * @notice can be called only by _guardian
     **/
    function abdicate() external;

    /**
     * @dev Getter of the current GovernanceStrategy address
     * @return The address of the current GovernanceStrategy contract
     **/
    function getGovernanceStrategy() external view returns (address);

    /**
     * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
     * Different from the voting duration
     * @return The voting delay in seconds
     **/
    function getVotingDelay() external view returns (uint256);

    /**
     * @dev Returns whether an address is an authorized executor
     * @param executor_ address to evaluate as authorized executor
     * @return true if authorized, false is not authorized
     **/
    function isExecutorAuthorized(address executor_)
        external
        view
        returns (bool);

    /**
     * @dev Getter the address of the guardian, that can mainly cancel proposals
     * @return The address of the guardian
     **/
    function getGuardian() external view returns (address);

    /**
     * @dev Getter of the proposal count (the current number of proposals ever created)
     * @return the proposal count
     **/
    function getProposalsCount() external view returns (uint256);

    /**
     * @dev Getter of the all proposals
     * @return array of all proposals
     **/
    function getProposals() external view returns (ProposalWithoutVotes[] memory);

    /**
     * @dev Getter of a proposal by id
     * @param proposalId id of the proposal to get
     * @return the proposal as ProposalWithoutVotes memory object
     **/
    function getProposalById(uint256 proposalId)
        external
        view
        returns (ProposalWithoutVotes memory);

    /**
     * @dev Getter of the Vote of a voter about a proposal
     * @notice Vote is a struct: ({bool support, uint248 votingPower})
     * @param proposalId id of the proposal
     * @param voter address of the voter
     * @return The associated Vote memory object
     **/
    function getVoteOnProposal(uint256 proposalId, address voter)
        external
        view
        returns (Vote memory);

    /**
     * @dev Get the current state of a proposal
     * @param proposalId id of the proposal
     * @return The current state if the proposal
     **/
    function getProposalState(uint256 proposalId)
        external
        view
        returns (ProposalState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../Constants.sol";
import "../lotteryGame/ConvertAvax.sol";

/**
 * @title Router contract
 * @author Applicature
 * @dev Contract for register AdditionalLottery contract as Keeper to track is game started and get winners
 */
contract Router is ConvertAvax{
    /// @notice registered additional lottery info
    /// @param lotteryRegisteredId getted id for registered additional lottery
    /// @param subscriptionId subscription id for VRF
    /// @param lotteryOwner owner of the additional lottery
    struct LotteriesInfo {
        uint256 lotteryRegisteredId;
        uint64 subscriptionId;
        address lotteryOwner;
    }

    /// @notice Emit when additional lottery registered as a keeper
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param lottery address to perform upkeep on
    /// @param keeperId subscription id for Keepers
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    event KeeperRegistered(
        string name,
        bytes encryptedEmail,
        address indexed lottery,
        uint256 indexed keeperId,
        uint32 gasLimit,
        bytes checkData,
        uint96 amount,
        uint8 source
    );

    /// @notice Emit when additional lottery registered as a VRF
    /// @param lottery address to perform VRF  on
    /// @param subscriptionId subscription id for VRF
    event VRFRegistered(
        address indexed lottery, 
        uint64 indexed subscriptionId
    );

    /// @notice minimal gas limit is needed to register the additional lottery as a keeper
    uint96 private constant MIN_GAS_LIMIT = 2300;
    /// @notice LINK token address
    LinkTokenInterface public immutable linkToken;
    /// @notice UpkeepRegistration contract address
    address public immutable upkeepRegistration;
    /// @notice KeeperRegistry contrct addressа
    address public immutable keeperRegistry;
    // id - address of the lottery => value
    mapping(address => LotteriesInfo) public registeredLotteries;
    mapping (address => uint64) public subscriptionId;

    constructor() ConvertAvax(LINK_TOKEN)  {
        linkToken = LinkTokenInterface(LINK_TOKEN);
        upkeepRegistration = UPKEEP_REGISTRATION;
        keeperRegistry = KEEPERS_REGISTRY;
    }

    /// @dev approve transfering tokens in LinkToken SC to Router SC before request keeper registration
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    /// @param lottery address to perform upkeep on
    function registerAdditionalLottery(
        string memory name,
        bytes memory encryptedEmail,
        uint32 gasLimit,
        bytes memory checkData,
        uint96 amount,
        uint8 source,
        address lottery
    ) external {
        require(gasLimit >= MIN_GAS_LIMIT, "LOW_GAS_LIMIT");
        require(amount >= MIN_LINK * DECIMALS, "LOW_AMOUNT");
        require(
            linkToken.balanceOf(address(this)) >= MIN_LINK * DECIMALS,
            "NOT_ENOUGHT_TOKENS"
        );

        registeredLotteries[lottery].lotteryOwner = msg.sender;

        (bool success, bytes memory returnData) = keeperRegistry.call(
            abi.encodeWithSignature("getUpkeepCount()")
        );
        require(success, "INVALID_CALL_GET");

        registeredLotteries[lottery].lotteryRegisteredId = abi.decode(
            returnData,
            (uint256)
        );

        // register as upkeep additional lottery
        linkToken.transferAndCall(
            upkeepRegistration,
            amount,
            abi.encodeWithSelector(
                bytes4(
                    keccak256(
                        "register(string,bytes,address,uint32,address,bytes,uint96,uint8)"
                    )
                ),
                name,
                encryptedEmail,
                lottery,
                gasLimit,
                address(this),
                checkData,
                amount,
                source
            )
        );

        emit KeeperRegistered(
            name,
            encryptedEmail,
            lottery,
            registeredLotteries[lottery].lotteryRegisteredId,
            gasLimit,
            checkData,
            amount,
            source
        );

        // register game for VRF work
        VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(VRF_COORDINATOR);
        uint64 subId = coordinator.createSubscription();
        coordinator.addConsumer(
            subId,
            lottery
        );

        registeredLotteries[lottery].subscriptionId = subId;

        emit VRFRegistered(lottery, subId);
    }

    /// @notice delete the additional lottaery from chainlink keepers tracking
    /// @param lottery address of the additional lottery
    function cancelSubscription(address lottery) external {
        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("cancelUpkeep(uint256)")),
                registeredLotteries[lottery].lotteryRegisteredId
            )
        );
        require(success, "INVALID_CALL_CANCEL");
        VRFCoordinatorV2Interface(VRF_COORDINATOR)
            .cancelSubscription(registeredLotteries[lottery].subscriptionId,  registeredLotteries[lottery].lotteryOwner);
        registeredLotteries[lottery].subscriptionId = 0;
    }

    /// @notice withdraw unused LINK tokens from keepers back to the owner of the additional lottery
    /// @param lottery address of the additional lottery
    function withdrawKeepers(address lottery) external {
        //withdraw tokens
        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("withdrawFunds(uint256,address)")),
                registeredLotteries[lottery].lotteryRegisteredId,
                registeredLotteries[lottery].lotteryOwner
            )
        );
        require(success, "INVALID_CALL_WITHDRAW");
    }

    /// @notice withdraw unused LINK tokens from VRF back to the owner of the additional lottery
    /// @param lottery address of the additional lottery
    function withdrawVRF(address lottery) external {
        //withdraw tokens
        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("withdrawFunds(uint256,address)")),
                registeredLotteries[lottery].lotteryRegisteredId,
                registeredLotteries[lottery].lotteryOwner
            )
        );
        require(success, "INVALID_CALL_WITHDRAW");
    }

    /// @notice pop up keeper with LINK tokens to continue tracking lottery
    /// @param lottery address of the additional lottery
    /// @param amountKeepers amount of LINK tokens to pop up kepeers
    /// @param amountVRF amount of LINK tokens to pop up VRF
    function addFunds(address lottery, uint96 amountKeepers, uint256 amountVRF) external {
        uint256 amount = amountKeepers + amountVRF;
        linkToken.transferFrom(msg.sender, address(this), amount);
        linkToken.approve(keeperRegistry, amount);

        (bool success, ) = keeperRegistry.call(
            abi.encodeWithSelector(
                bytes4(keccak256("addFunds(uint256,uint96)")),
                registeredLotteries[lottery].lotteryRegisteredId,
                amountKeepers
            )
        );

        require(success, "INVALID_CALL_ADD_FUNDS");

        linkToken.transferAndCall(
            VRF_COORDINATOR,
            amountVRF,
            abi.encode(registeredLotteries[lottery].subscriptionId)
        );
    }

    function getSubscriptionId(address lottery) external view returns(uint64){
        return registeredLotteries[lottery].subscriptionId;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// chainlink
address constant VRF_COORDINATOR = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
address constant KEEPERS_REGISTRY = 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2; //0x409CF388DaB66275dA3e44005D182c12EeAa12A0;
address constant LINK_TOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
address constant UPKEEP_REGISTRATION = 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2;//0xb3532682f7905e06e746314F6b12C1e988B94aDB;
//lottery
uint256 constant WINNERS_LIMIT = 10;
uint256 constant BENEFICIARY_LIMIT = 100;
uint256 constant HUNDRED_PERCENT_WITH_PRECISONS = 10_000;
uint256 constant FIFTY_PERCENT_WITH_PRECISONS = 5_000;
uint256 constant MIN_LINK_TOKENS_NEEDDED = 5 ether;
uint256 constant DECIMALS = 1 ether;
uint8 constant MIN_LINK = 5;
//convert avax<>link
address constant PANGOLIN_ROUTER = 0x3705aBF712ccD4fc56Ee76f0BD3009FD4013ad75;

error ZeroAddress();
error ZeroAmount();
error IncorrectLength();
error IncorrectPercentsSum();
error IncorrectPercentsValue();
error GameDeactivated();
error IncorrectTimelock();
error UnderLimit();
error GameNotReadyToStart();
error ParticipateAlready();
error InvalidParticipatee();
error LimitExeed();
error IsDeactivated();
error SubscriptionIsEmpty();
error SubscriptionIsNotEmpty();
error GameIsNotActive();
error GameIsStarted();
error UnderParticipanceLimit();
error InvalidEntryFee();
error InvalidCallerFee();
error InvalidTimelock();
error AnuthorizedCaller();
error InsufficientBalance();

string constant ERROR_INCORRECT_LENGTH = "0x1";
string constant ERROR_INCORRECT_PERCENTS_SUM = "0x2";
string constant ERROR_DEACTIVATED_GAME = "0x3";
string constant ERROR_CALLER_FEE_CANNOT_BE_MORE_100 = "0x4";
string constant ERROR_TIMELOCK_IN_DURATION_IS_ACTIVE = "0x5";
string constant ERROR_DATE_TIME_TIMELOCK_IS_ACTIVE = "0x6";
string constant ERROR_LIMIT_UNDER = "0x7";
string constant ERROR_INCORRECT_PERCENTS_LENGTH = "0x8";
string constant ERROR_NOT_READY_TO_START = "0x9";
string constant ERROR_NOT_ACTIVE_OR_STARTED = "0xa";
string constant ERROR_PARTICIPATE_ALREADY = "0xb";
string constant ERROR_INVALID_PARTICIPATE = "0xc";
string constant ERROR_LIMIT_EXEED = "0xd";
string constant ERROR_ALREADY_DEACTIVATED = "0xe";
string constant ERROR_GAME_STARTED = "0xf";
string constant ERROR_NO_SUBSCRIPTION = "0x10";
string constant ERROR_NOT_ACTIVE = "0x11";
string constant ERROR_ZERO_ADDRESS = "0x12";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* solhint-disable var-name-mixedcase */
interface ICustomLotteryGame {
    /// @notice store more detailed info about the additional game
    /// @param VRFGasLimit amount of the gas limit for VRF
    /// @param countOfWinners number of winners
    /// @param participantsLimit limit of users that can be in game
    /// @param participantsCount number of user that are already in game
    /// @param participationFee amount of fee for user to enter the game
    /// @param callerFeePercents amount of fee percentage for caller of the game
    /// @param gameDuration timestamp how long the game should be going
    /// @param isDeactivated bool value is the game is deactibated (true) or not (false)
    /// @param callerFeeCollector address of the caller fee percentage
    /// @param lotteryName the name of the lottery game
    /// @param descriptionIPFS ipfs hash with lottery description
    /// @param winnersPercentages array of winners percentage
    /// @param benefeciaryPercentage array of beneficiary reward percentage
    /// @param subcriptorsList array of subscriptors
    /// @param benefeciaries array of lottery beneficiaries
    struct Game {
        uint32 VRFGasLimit;
        uint256 countOfWinners;
        uint256 participantsLimit;
        uint256 participantsCount;
        uint256 participationFee;
        uint256 callerFeePercents;
        uint256 gameDuration;
        bool isDateTimeRequired;
        bool isDeactivated;
        address callerFeeCollector;
        string lotteryName;
        string descriptionIPFS;
        uint256[] winnersPercentages;
        uint256[] benefeciaryPercentage;
        address[] subcriptorsList;
        address[] benefeciaries;
    }

    struct EmptyTypes {
        address[] emptyAddr;
        uint256[] emptyUInt;
    }

    /// @notice store lottery (rounds) info
    /// @param rewardPool address of the reward pool
    /// @param isActive is active
    /// @param id lottery id
    /// @param participationFee paricipation fee for user to enter lottery
    /// @param startedAt timestamp when the lottery is started
    /// @param finishedAt timestamp when the lottery is finished
    /// @param rewards amount of the rewards
    /// @param winningPrize array of amount for each winner
    /// @param beneficiariesPrize array of amount for each beneficiary
    /// @param participants array of lottery participants
    /// @param winners array of lottery winners
    /// @param beneficiaries array of lottery beneficiaries
    struct Lottery {
        address rewardPool;
        bool isActive;
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 rewards;
        uint256[] winningPrize;
        uint256[] beneficiariesPrize;
        address[] participants;
        address[] winners;
        address[] beneficiaries;
    }

    /// @notice store subscription info
    /// @param isExist is user subscribe
    /// @param isRevoked is user unsubscribe
    /// @param balance user balance of withdrawn money in subscription after a round
    /// @param lastCheckedGameId the game (round) id from which will be active yser`s subscription
    struct Subscription {
        bool isExist;
        bool isRevoked;
        uint256 balance;
        uint256 lastCheckedGameId;
    }

    /// @notice store game options info
    /// @param countOfParticipants number of participants in a round
    /// @param winnersIndexes array of winners indexes
    struct GameOptionsInfo {
        uint256 countOfParticipants;
        uint256[] winnersIndexes;
    }

    /// @notice store chainlink parameters info
    /// @param requestConfirmations amount of confiramtions for VRF
    /// @param keeperId subscription id for Keepers
    /// @param subscriptionId subscription id for VRF
    /// @param keyHash The gas lane to use, which specifies the maximum gas price to bump to while VRF
    struct ChainlinkParameters {
        uint16 requestConfirmations;
        uint256 keeperId;
        uint64 subscriptionId;
        bytes32 keyHash;
    }

    /// @notice store winning prize info
    /// @param totalWinningPrize amount of total winning prize of jeckpot
    /// @param callerFee percentage of caller fee for jeckpot
    /// @param governanceFee percentage of game tokens as a governance rewatds from jeckpot
    /// @param communityFee percentage of game tokens as a community rewatds from jeckpot
    /// @param governanceReward amount of game tokens as a governance rewatds from jeckpot
    /// @param communityReward amount of game tokens as a community rewatds from jeckpot
    /// @param totalReward percentage of total rewards from jeckpot
    /// @param beneficiariesPrize percentage of beneficiary prize of jeckpot
    /// @param totalWinningPrizeExludingFees amount of total winning prize without fees of jeckpot
    struct WinningPrize {
        uint256 totalWinningPrize;
        uint256 callerFee;
        uint256 governanceFee;
        uint256 communityFee;
        uint256 governanceReward;
        uint256 communityReward;
        uint256 totalReward;
        uint256 beneficiariesPrize;
        uint256 totalWinningPrizeExludingFees;
    }

    /// @notice store all chenging params for the game
    /// @dev this pending params are setted to the game from the next round
    /// @param isDeactivated is game active or not
    /// @param participationFee  participation fee for the game
    /// @param winnersNumber count of winners
    /// @param winnersPercentages array of percenages for winners
    /// @param limitOfPlayers participants limit
    /// @param callerFeePercents caller fee percntages
    struct Pending {
        bool isDeactivated;
        uint256 participationFee;
        uint256 winnersNumber;
        uint256 limitOfPlayers;
        uint256 callerFeePercents;
        uint256[] winnersPercentages;
    }

    /// @notice store info about time when lottery is unlocked
    /// @dev should be in unix, so need to take care about conversion into required timezone
    /// @param daysUnlocked day of week when game is unlock
    /// @param hoursStartUnlock start hour when game is unlocking
    /// @param unlockDurations unlock duration starting from hoursStartUnlock
    struct TimelockInfo {
        uint8[] daysUnlocked;
        uint8[] hoursStartUnlock;
        uint256[] unlockDurations;
    }

    /// @notice emitted when called fullfillBytes
    /// @param requestId encoded request id
    /// @param data encoded data
    // event RequestFulfilled(bytes32 indexed requestId, bytes indexed data);

    /// @notice emitted when the game is started
    /// @param id the game id
    /// @param startedAt timestamp when game is started
    event GameStarted(uint256 indexed id, uint256 indexed startedAt);

    /// @notice emitted when the game is finished
    /// @param id the game id
    /// @param startedAt timestamp when game is started
    /// @param finishedAt timestamp when game is finished
    /// @param participants array of games participants
    /// @param winners array of winners
    /// @param participationFee participation fee for users to enter to the game
    /// @param winningPrize array of prizes for each winner
    /// @param rewards amount of jeckpot rewards
    /// @param rewardPool reward pool of the game
    event GameFinished(
        uint256 id,
        uint256 startedAt,
        uint256 finishedAt,
        address[] indexed participants,
        address[] indexed winners,
        uint256 participationFee,
        uint256[] winningPrize,
        uint256 rewards,
        address indexed rewardPool
    );

    /// @notice emitted when a game duration is change
    /// @param gameDuration timestamp of the game duration
    event ChangedGameDuration(uint256 gameDuration);

    /// @notice emitted when a game amount of winners is change
    /// @param winnersNumber new amount of winners
    /// @param winnersPercentages new percentage
    event ChangedWinners(uint256 winnersNumber, uint256[] winnersPercentages);

    /// @notice Enter game for following one round
    /// @dev participant address is msg.sender
    function entryGame() external;

    /// @notice Enter game for following one round
    /// @dev participatinonFee will be charged from msg.sender
    /// @param participant address of the participant
    function entryGame(address participant) external;

    /// @notice start created game
    /// @param VRFGasLimit_ price for VRF
    function startGame(uint32 VRFGasLimit_) external payable;

    /// @notice deactivation game
    /// @dev if the game is deactivated cannot be called entryGame()  and subcribe()
    function deactivateGame() external;

    /// @notice get participation fee for LotteryGameFactory contract
    function getParticipationFee() external view returns (uint256);

    /// @notice set time lock if the game will be locked
    /// @param timelock_ time lock for the locked lottery game
    function setTimelock(TimelockInfo memory timelock_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IGovernance.sol";

interface IExecutor {
    /**
     * @notice Struct for track LINK tokens balance when creating proposal
     * @param amount amount of LINK tokens in Executor balance
     * @param isWithdrawed is Link tokens withdraw to the owner address
     * @param governance address of Governance contract
     **/
    struct LinkTokensInfo {
        uint256 amount;
        bool isWithdrawed;
        address governance;
    }

    /**
     * @dev emitted when a new pending admin is set
     * @param newPendingAdmin address of the new pending admin
     **/
    event NewPendingAdmin(address newPendingAdmin);

    /**
     * @dev emitted when a new admin is set
     * @param newAdmin address of the new admin
     **/
    event NewAdmin(address newAdmin);

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param resultData the actual callData used on the target
     **/
    event ExecutedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bytes resultData
    );

    /// @notice deposit LINK tokens to Executor contract 
    /// @dev can be called by the governance contract only
    /// @param proposalCreator address of proposal creator
    /// @param amount quantity of LINK upkeep is funded
    /// @param proposalId created proposal id
    function depositLinks(address proposalCreator, uint256 amount, uint256 proposalId) external;

    /// @notice withdraw LINK tokens by the proposal creator
    /// @dev can be called only when proposal is failed/not executed/canceled
    /// @param proposalId id of proposal need to withdraw link tokens from
    function withdrawLinks(uint256 proposalId) external;

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view returns (address);

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view returns (address);

    /**
     * @dev Checks whether a proposal is over its grace period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over grace period
     **/
    function isProposalOverExecutionPeriod(
        IGovernance governance,
        uint256 proposalId
    ) external view returns (bool);

    /**
     * @dev Getter of execution period constant
     * @return grace period in seconds
     **/
    function executionPeriod() external view returns (uint256);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 executionTime
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/pangolin/IPangolinRouter.sol";
import "../Constants.sol";

contract ConvertAvax{
    IPangolinRouter private constant PANGOLIN = IPangolinRouter(PANGOLIN_ROUTER);
    address internal immutable LINK;
    address internal immutable WAVAX;

    event Swap(uint256 indexed amountIn, uint256 amountMin, address[] path);
    constructor(address link_){
        WAVAX = PANGOLIN.WAVAX();
        LINK = link_;
    }

    function _swapAvaxToLink(address to) internal {
        uint256 amountIn = msg.value;
        if (amountIn == 0){
            revert ZeroAmount();
        }
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = LINK;
        uint256 amountOutMin = getAmountOutMin(path, amountIn);
        PANGOLIN.swapExactAVAXForTokens{value: amountIn}(amountOutMin, path, to, block.timestamp + 1 hours);
    }

    function swapAvaxToLink(address to) public payable {
        swapAvaxToLink(to);
    }

    function getAmountOutMin(address[] memory path_, uint256 amountIn_) private view returns (uint256) {        
        uint256[] memory amountOutMins = PANGOLIN.getAmountsOut(amountIn_, path_);
        return amountOutMins[path_.length - 1];  
    } 

}


/// WBTC = 0x5d870A421650C4f39aE3f5eCB10cBEEd36e6dF50
/// PartyROuter = 0x3705aBF712ccD4fc56Ee76f0BD3009FD4013ad75
/// PagolinRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}