// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/access/Ownable.sol";
import "joe-v2/interfaces/ILBPair.sol";
import "../interfaces/ILBStrategy.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/// @title LBActiveStratManager V2
/// @author SteakHut Finance
/// @notice contract to enable rebalances of the underlying strategy using existing parameters
/// @notice this strategy will chase an active bin once it goes within x number bins of current range
/// @notice this strategy will also perform a rebalance once it becomes one sided
contract LBActiveStratManagerActiveV2 is Ownable, AutomationCompatibleInterface {
    using SafeERC20 for IERC20;

    address public immutable strategyAddress;
    uint256 public binOffset;

    //tracks rebalances and attempts to ~equal weight on next rebalance
    bool public isTokenXWeighted;
    bool public isTokenYWeighted;
    uint256 public centerOffset;

    //harvesting params
    uint256 public lastTimestamp;
    uint256 public period = 21600; //6 hours
    address public gasCaller;

    /// -----------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------

    constructor(address _strategyAddress, address _gasCaller, uint256 _binOffset, uint256 _centerOffset) {
        strategyAddress = _strategyAddress;
        binOffset = _binOffset;
        gasCaller = _gasCaller;
        centerOffset = _centerOffset;
    }

    /// -----------------------------------------------------------
    /// Manager Functions
    /// -----------------------------------------------------------

    /// @notice Updates binOffset
    /// @param _binOffset new bin offset.
    function setBinOffset(uint256 _binOffset) external onlyOwner {
        require(_binOffset >= 0, "Manager: Bin offset too small");
        binOffset = _binOffset;
    }

    /// @notice Updates centerOffset
    /// @param _centerOffset new center offset.
    function setCenterOffset(uint256 _centerOffset) external onlyOwner {
        require(_centerOffset >= 0, "Manager: Center offset too small");
        centerOffset = _centerOffset;
    }

    /// @notice Updates fee recipient for gas reimbursement
    /// @param _gasCaller address.
    function setGasCaller(address _gasCaller) external onlyOwner {
        require(address(_gasCaller) != address(0), "Manager: Address 0");
        gasCaller = _gasCaller;
    }

    /// @notice Updates the minimum period between harvests
    /// @param _period new minimum period.
    function setPeriod(uint256 _period) external onlyOwner {
        require(_period > 3600, "Manager: Period too small");
        period = _period;
    }

    /// @notice Rescues funds stuck
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /// @notice manual rebalance underlying position
    function manualRebalance() external onlyOwner {
        //set the weightings to be neutral as manual rebalance
        isTokenYWeighted = false;
        isTokenXWeighted = false;

        ILBStrategy(strategyAddress).executeRebalance();
    }

    /// @notice manual rebalance underlying position and set new range
    function manualRebalanceSetRange(
        int256[] memory _deltaIds,
        uint256[] memory _distributionX,
        uint256[] memory _distributionY,
        uint256 _idSlippage
    ) external onlyOwner {
        //set the weightings to be neutral as manual rebalance
        isTokenYWeighted = false;
        isTokenXWeighted = false;

        ILBStrategy(strategyAddress).executeRebalance(_deltaIds, _distributionX, _distributionY, _idSlippage);
    }

    function transferKeeper(address _keeper) external onlyOwner {
        ILBStrategy(strategyAddress).setKeeper(_keeper);
    }

    /// -----------------------------------------------------------
    /// View / Pure Functions
    /// -----------------------------------------------------------

    /// @notice returns the minimum and maximum bin currently used by the underlying strategy
    function _checkMinMaxActiveBins(uint256[] memory activeBins) public pure returns (uint256 minBin, uint256 maxBin) {
        //do a first run and set min bin to the first item
        bool isFirstRun = true;

        for (uint256 i; i < activeBins.length; i++) {
            if (activeBins[i] < minBin || isFirstRun) {
                minBin = activeBins[i];
                isFirstRun = false;
            }
            if (activeBins[i] > maxBin) {
                maxBin = activeBins[i];
            }
        }
    }

    /// -----------------------------------------------------------
    /// Chainlink Functions
    /// -----------------------------------------------------------

    /// @notice Chainlink Check Upkeep Function
    /// @notice checks to moves liquidity around the active bin once binOffset is achieved
    /// @notice checks if enough time has passed to perform a harvest only
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;

        //fetch all the active bins in the strategy
        uint256[] memory activeBins = ILBStrategy(strategyAddress).strategyActiveBins();
        (uint256 minBin, uint256 maxBin) = _checkMinMaxActiveBins(activeBins);

        //get the center of the active bins
        uint256 binLength = activeBins.length;
        uint256 centerBin = binLength / 2;
        uint256 minCenterBin = activeBins[centerBin - centerOffset];
        uint256 maxCenterBin = activeBins[centerBin + centerOffset];

        //fetch the current activeId of the lb pair
        address _lbPair = ILBStrategy(strategyAddress).lbPair();
        (,, uint256 activeId) = ILBPair(_lbPair).getReservesAndId();

        //if the active bin is within binOffset of the active bin rebalance the underlying strategy
        if (activeId <= minBin + binOffset) {
            upkeepNeeded = true;
        }
        if (activeId >= maxBin - binOffset) {
            upkeepNeeded = true;
        }

        //if the ratio is skewed rebalance to get ratio back to equal weight
        if ((activeId <= minCenterBin && isTokenYWeighted) || (activeId >= maxCenterBin && isTokenXWeighted)) {
            //requires upkeep to equal weight bins
            upkeepNeeded = true;
        }

        //require an upkeep if there has been minimum time between harvests
        if (block.timestamp > lastTimestamp + period) {
            upkeepNeeded = true;
        }

        performData; //silence unused parameter
    }

    /// @notice Chainlink Perform Upkeep Function
    /// @notice moves liquidity around the active bin once binOffset is achieved
    /// @notice harvest if enough time has passed to perform a harvest only
    function performUpkeep(bytes calldata) external override {
        //get the underlying lbPair and activeId
        address _lbPair = ILBStrategy(strategyAddress).lbPair();
        (,, uint256 activeId) = ILBPair(_lbPair).getReservesAndId();

        //fetch the active bins in the strategy
        uint256[] memory activeBins = ILBStrategy(strategyAddress).strategyActiveBins();

        // check the min and max active bins
        (uint256 minBin, uint256 maxBin) = _checkMinMaxActiveBins(activeBins);

        //get the center of the active bins
        uint256 binLength = activeBins.length;
        uint256 centerBin = binLength / 2;
        uint256 minCenterBin = activeBins[centerBin - centerOffset];
        uint256 maxCenterBin = activeBins[centerBin + centerOffset];

        //revalidating the upkeep in the performUpkeep function
        //if the active bin is within binOffset of the active bin rebalance the underlying strategy
        //idle strategy funds are put to work on the next rebalance
        //we dont need to check bin limit as funds will always be the underlying bin length
        if (activeId <= minBin + binOffset || activeId >= maxBin - binOffset) {
            //the liquidty upon this rebalance will be skewed so turn on trigger switch for next
            if (activeId <= minBin + binOffset) {
                //strategy is token X weighted
                isTokenXWeighted = true;
                isTokenYWeighted = false;
            }
            if (activeId >= maxBin - binOffset) {
                //strategy is token Y weighted
                isTokenXWeighted = false;
                isTokenYWeighted = true;
            }

            //rebalance keeping the same parameters as before
            //does not require a harvest as executeRebalance handles this
            ILBStrategy(strategyAddress).executeRebalance();
        } else if ((activeId <= minCenterBin && isTokenYWeighted) || (activeId >= maxCenterBin && isTokenXWeighted)) {
            //reset the weighting switch
            isTokenYWeighted = false;
            isTokenXWeighted = false;

            //rebalance keeping the same parameters as before
            //does not require a harvest as executeRebalance handles this
            ILBStrategy(strategyAddress).executeRebalance();
        } else {
            //harvest rewards from strategy; can be called anytime
            _harvest(gasCaller);
        }
    }

    /// -----------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------

    /// @notice executes a harvest of the associated strategy
    /// @param callFeeRecipient address of strategy that needs a harvest
    function _harvest(address callFeeRecipient) internal {
        ILBStrategy strategy = ILBStrategy(strategyAddress);
        strategy.harvest(callFeeRecipient);

        //update the last harvest timestamp
        lastTimestamp = block.timestamp;
    }

    /// -----------------------------------------------------------
    /// END
    /// -----------------------------------------------------------
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

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

import "../libraries/FeeHelper.sol";
import "./ILBFactory.sol";
import "./ILBFlashLoanCallback.sol";

/// @title Liquidity Book Pair Interface
/// @author Trader Joe
/// @notice Required interface of LBPair contract
interface ILBPair {
    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeeHelper.FeesDistribution feesX;
        FeeHelper.FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        bool swapForY,
        uint256 amountIn,
        uint256 amountOut,
        uint256 volatilityAccumulated,
        uint256 fees
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        IERC20 token,
        uint256 amount,
        uint256 fee
    );

    event CompositionFee(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 feesX,
        uint256 feesY
    );

    event DepositedToBin(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 amountX,
        uint256 amountY
    );

    event WithdrawnFromBin(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 amountX,
        uint256 amountY
    );

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (ILBFactory);

    function getReservesAndId()
        external
        view
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        );

    function getGlobalFees()
        external
        view
        returns (
            uint128 feesXTotal,
            uint128 feesYTotal,
            uint128 feesXProtocol,
            uint128 feesYProtocol
        );

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(uint256 timeDelta)
        external
        view
        returns (
            uint256 cumulativeId,
            uint256 cumulativeAccumulator,
            uint256 cumulativeBinCrossed
        );

    function feeParameters() external view returns (FeeHelper.FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(
        ILBFlashLoanCallback receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    )
        external
        returns (
            uint256 amountXAddedToPair,
            uint256 amountYAddedToPair,
            uint256[] memory liquidityMinted
        );

    function burn(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address to
    ) external returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 sampleLifetime,
        bytes32 packedFeeParameters
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

interface ILBStrategy {
    /// @notice The liquidity parameters, such as:
    /// @param tokenX: The address of token X
    /// @param tokenY: The address of token Y
    /// @param pair: The address of the LB pair
    /// @param binStep: BinStep as per LB Pair
    /// @param deltaIds: the bins you want to add liquidity to. Each value is relative to the active bin ID
    /// @param distributionX: The percentage of X you want to add to each bin in deltaIds
    /// @param distributionY: The percentage of Y you want to add to each bin in deltaIds
    /// @param idSlippage: The slippage tolerance in case active bin moves during time it takes to transact
    struct StrategyParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        address pair;
        uint16 binStep;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        uint256 idSlippage;
    }

    function deltaIds() external view returns (int256[] memory deltaIds);

    function distributionX()
        external
        view
        returns (uint256[] memory distributionX);

    function distributionY()
        external
        view
        returns (uint256[] memory distributionY);

    function idSlippage() external view returns (uint256);

    function vault() external view returns (address);

    function lbPair() external view returns (address);

    function setKeeper(address _keeper) external;

    function keeper() external view returns (address);

    function strategyPositionAtIndex(
        uint256 _index
    ) external view returns (uint256);

    function strategyPositionNumber() external view returns (uint256);

    function checkProposedBinLength(
        int256[] memory proposedDeltas,
        uint256 activeId
    ) external view returns (uint256);

    function addLiquidity(
        uint256 amountX,
        uint256 amountY,
        uint256 amountXMin,
        uint256 amountYMin
    ) external returns (uint256[] memory liquidityMinted);

    function binStep() external view returns (uint16);

    function balanceOfLiquidities()
        external
        view
        returns (uint256 totalLiquidityBalance);

    function removeLiquidity(
        uint256 denominator
    ) external returns (uint256 amountX, uint256 amountY);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function harvest() external;

    function harvest(
        address callFeeRecipient
    ) external returns (uint256 amountXReceived, uint256 amountYReceived);

    function earn() external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function joeRouter() external view returns (address);

    function binHasYLiquidity(
        int256[] memory _deltaIds
    ) external view returns (bool hasYLiquidity);

    function binHasXLiquidity(
        int256[] memory _deltaIds
    ) external view returns (bool hasXLiquidity);

    function beforeDeposit() external;

    function rewardsAvailable()
        external
        view
        returns (uint256 rewardsX, uint256 rewardsY);

    function executeRebalance(
        int256[] memory _deltaIds,
        uint256[] memory _distributionX,
        uint256[] memory _distributionY,
        uint256 _idSlippage
    ) external returns (uint256 liquidityAfter);

    function executeRebalance()
        external
        returns (uint256 amountX, uint256 amountY);

    function checkLengthsPerformRebalance() external;

    function strategyActiveBins()
        external
        view
        returns (uint256[] memory activeBins);

    function getBalanceX() external view returns (uint256);

    function getBalanceY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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

pragma solidity 0.8.10;

import "./Constants.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";

/// @title Liquidity Book Fee Helper Library
/// @author Trader Joe
/// @notice Helper contract used for fees calculation
library FeeHelper {
    using SafeCast for uint256;
    using SafeMath for uint256;

    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @notice Update the value of the volatility accumulated
    /// @param _fp The current fee parameters
    /// @param _activeId The current active id
    function updateVariableFeeParameters(FeeParameters memory _fp, uint256 _activeId) internal view {
        uint256 _deltaT = block.timestamp - _fp.time;

        if (_deltaT >= _fp.filterPeriod || _fp.time == 0) {
            _fp.indexRef = uint24(_activeId);
            if (_deltaT < _fp.decayPeriod) {
                unchecked {
                    // This can't overflow as `reductionFactor <= BASIS_POINT_MAX`
                    _fp.volatilityReference = uint24(
                        (uint256(_fp.reductionFactor) * _fp.volatilityAccumulated) / Constants.BASIS_POINT_MAX
                    );
                }
            } else {
                _fp.volatilityReference = 0;
            }
        }

        _fp.time = (block.timestamp).safe40();

        updateVolatilityAccumulated(_fp, _activeId);
    }

    /// @notice Update the volatility accumulated
    /// @param _fp The fee parameter
    /// @param _activeId The current active id
    function updateVolatilityAccumulated(FeeParameters memory _fp, uint256 _activeId) internal pure {
        uint256 volatilityAccumulated = (_activeId.absSub(_fp.indexRef) * Constants.BASIS_POINT_MAX) +
            _fp.volatilityReference;
        _fp.volatilityAccumulated = volatilityAccumulated > _fp.maxVolatilityAccumulated
            ? _fp.maxVolatilityAccumulated
            : uint24(volatilityAccumulated);
    }

    /// @notice Returns the base fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return The fee with 18 decimals precision
    function getBaseFee(FeeParameters memory _fp) internal pure returns (uint256) {
        unchecked {
            return uint256(_fp.baseFactor) * _fp.binStep * 1e10;
        }
    }

    /// @notice Returns the variable fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return variableFee The variable fee with 18 decimals precision
    function getVariableFee(FeeParameters memory _fp) internal pure returns (uint256 variableFee) {
        if (_fp.variableFeeControl != 0) {
            // Can't overflow as the max value is `max(uint24) * (max(uint24) * max(uint16)) ** 2 < max(uint104)`
            // It returns 18 decimals as:
            // decimals(variableFeeControl * (volatilityAccumulated * binStep)**2 / 100) = 4 + (4 + 4) * 2 - 2 = 18
            unchecked {
                uint256 _prod = uint256(_fp.volatilityAccumulated) * _fp.binStep;
                variableFee = (_prod * _prod * _fp.variableFeeControl + 99) / 100;
            }
        }
    }

    /// @notice Return the amount of fees from an amount
    /// @dev Rounds amount up, follows `amount = amountWithFees - getFeeAmountFrom(fp, amountWithFees)`
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount from the amount sent
    function getFeeAmountFrom(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        return (_amountWithFees * getTotalFee(_fp) + Constants.PRECISION - 1) / (Constants.PRECISION);
    }

    /// @notice Return the fees to add to an amount
    /// @dev Rounds amount up, follows `amountWithFees = amount + getFeeAmount(fp, amount)`
    /// @param _fp The current fee parameter
    /// @param _amount The amount of token sent
    /// @return The fee amount to add to the amount
    function getFeeAmount(FeeParameters memory _fp, uint256 _amount) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION - _fee;
        return (_amount * _fee + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees added when an user adds liquidity and change the ratio in the active bin
    /// @dev Rounds amount up
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount
    function getFeeAmountForC(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION * Constants.PRECISION;
        return (_amountWithFees * _fee * (_fee + Constants.PRECISION) + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees distribution added to an amount
    /// @param _fp The current fee parameter
    /// @param _fees The fee amount
    /// @return fees The fee distribution
    function getFeeAmountDistribution(FeeParameters memory _fp, uint256 _fees)
        internal
        pure
        returns (FeesDistribution memory fees)
    {
        fees.total = _fees.safe128();
        // unsafe math is fine because total >= protocol
        unchecked {
            fees.protocol = uint128((_fees * _fp.protocolShare) / Constants.BASIS_POINT_MAX);
        }
    }

    /// @notice Return the total fee, i.e. baseFee + variableFee
    /// @param _fp The current fee parameter
    /// @return The total fee, with 18 decimals
    function getTotalFee(FeeParameters memory _fp) private pure returns (uint256) {
        unchecked {
            return getBaseFee(_fp) + getVariableFee(_fp);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

import "./ILBPair.sol";
import "./IPendingOwnable.sol";

/// @title Liquidity Book Factory Interface
/// @author Trader Joe
/// @notice Required interface of LBFactory contract
interface ILBFactory is IPendingOwnable {
    /// @dev Structure to store the LBPair information, such as:
    /// - binStep: The bin step of the LBPair
    /// - LBPair: The address of the LBPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX,
        IERC20 indexed tokenY,
        uint256 indexed binStep,
        ILBPair LBPair,
        uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event FeeParametersSet(
        address indexed sender,
        ILBPair indexed LBPair,
        uint256 binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulated
    );

    event FactoryLockedStatusUpdated(bool unlocked);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulated,
        uint256 sampleLifetime
    );

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    function LBPairImplementation() external view returns (address);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function creationUnlocked() external view returns (bool);

    function allLBPairs(uint256 id) external returns (ILBPair);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairInformation(
        IERC20 tokenX,
        IERC20 tokenY,
        uint256 binStep
    ) external view returns (LBPairInformation memory);

    function getPreset(uint16 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            uint256 sampleLifetime
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address LBPairImplementation) external;

    function createLBPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 binStep
    ) external returns (ILBPair pair);

    function setLBPairIgnored(
        IERC20 tokenX,
        IERC20 tokenY,
        uint256 binStep,
        bool ignored
    ) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulated,
        uint16 sampleLifetime
    ) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulated
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function setFactoryLockedState(bool locked) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair LBPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Liquidity Book Constants Library
/// @author Trader Joe
/// @notice Set of constants for Liquidity Book contracts
library Constants {
    uint256 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET;

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../LBErrors.sol";

/// @title Liquidity Book Safe Cast Library
/// @author Trader Joe
/// @notice Helper contract used for converting uint values safely
library SafeCast {
    /// @notice Returns x on uint248 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint248
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits(x);
    }

    /// @notice Returns x on uint240 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint240
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits(x);
    }

    /// @notice Returns x on uint232 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint232
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits(x);
    }

    /// @notice Returns x on uint224 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint224
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits(x);
    }

    /// @notice Returns x on uint216 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint216
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits(x);
    }

    /// @notice Returns x on uint208 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint208
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits(x);
    }

    /// @notice Returns x on uint200 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint200
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits(x);
    }

    /// @notice Returns x on uint192 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint192
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits(x);
    }

    /// @notice Returns x on uint184 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint184
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits(x);
    }

    /// @notice Returns x on uint176 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint176
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits(x);
    }

    /// @notice Returns x on uint168 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint168
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits(x);
    }

    /// @notice Returns x on uint160 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint160
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits(x);
    }

    /// @notice Returns x on uint152 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint152
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits(x);
    }

    /// @notice Returns x on uint144 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint144
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits(x);
    }

    /// @notice Returns x on uint136 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint136
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits(x);
    }

    /// @notice Returns x on uint128 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint128
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits(x);
    }

    /// @notice Returns x on uint120 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint120
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits(x);
    }

    /// @notice Returns x on uint112 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint112
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits(x);
    }

    /// @notice Returns x on uint104 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint104
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits(x);
    }

    /// @notice Returns x on uint96 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint96
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits(x);
    }

    /// @notice Returns x on uint88 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint88
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits(x);
    }

    /// @notice Returns x on uint80 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint80
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits(x);
    }

    /// @notice Returns x on uint72 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint72
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits(x);
    }

    /// @notice Returns x on uint64 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint64
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits(x);
    }

    /// @notice Returns x on uint56 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint56
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits(x);
    }

    /// @notice Returns x on uint48 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint48
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits(x);
    }

    /// @notice Returns x on uint40 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint40
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits(x);
    }

    /// @notice Returns x on uint32 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint32
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits(x);
    }

    /// @notice Returns x on uint24 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint24
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits(x);
    }

    /// @notice Returns x on uint16 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint16
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits(x);
    }

    /// @notice Returns x on uint8 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint8
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits(x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Liquidity Book Safe Math Helper Library
/// @author Trader Joe
/// @notice Helper contract used for calculating absolute value safely
library SafeMath {
    /// @notice absSub, can't underflow or overflow
    /// @param x The first value
    /// @param y The second value
    /// @return The result of abs(x - y)
    function absSub(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            return x > y ? x - y : y - x;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Liquidity Book Pending Ownable Interface
/// @author Trader Joe
/// @notice Required interface of Pending Ownable contract used for LBFactory
interface IPendingOwnable {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/ILBPair.sol";

/** LBRouter errors */

error LBRouter__SenderIsNotWAVAX();
error LBRouter__PairNotCreated(address tokenX, address tokenY, uint256 binStep);
error LBRouter__WrongAmounts(uint256 amount, uint256 reserve);
error LBRouter__SwapOverflows(uint256 id);
error LBRouter__BrokenSwapSafetyCheck();
error LBRouter__NotFactoryOwner();
error LBRouter__TooMuchTokensIn(uint256 excess);
error LBRouter__BinReserveOverflows(uint256 id);
error LBRouter__IdOverflows(int256 id);
error LBRouter__LengthsMismatch();
error LBRouter__WrongTokenOrder();
error LBRouter__IdSlippageCaught(uint256 activeIdDesired, uint256 idSlippage, uint256 activeId);
error LBRouter__AmountSlippageCaught(uint256 amountXMin, uint256 amountX, uint256 amountYMin, uint256 amountY);
error LBRouter__IdDesiredOverflows(uint256 idDesired, uint256 idSlippage);
error LBRouter__FailedToSendAVAX(address recipient, uint256 amount);
error LBRouter__DeadlineExceeded(uint256 deadline, uint256 currentTimestamp);
error LBRouter__AmountSlippageBPTooBig(uint256 amountSlippage);
error LBRouter__InsufficientAmountOut(uint256 amountOutMin, uint256 amountOut);
error LBRouter__MaxAmountInExceeded(uint256 amountInMax, uint256 amountIn);
error LBRouter__InvalidTokenPath(address wrongToken);
error LBRouter__InvalidVersion(uint256 version);
error LBRouter__WrongAvaxLiquidityParameters(
    address tokenX,
    address tokenY,
    uint256 amountX,
    uint256 amountY,
    uint256 msgValue
);

/** LBToken errors */

error LBToken__SpenderNotApproved(address owner, address spender);
error LBToken__TransferFromOrToAddress0();
error LBToken__MintToAddress0();
error LBToken__BurnFromAddress0();
error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);
error LBToken__LengthMismatch(uint256 accountsLength, uint256 idsLength);
error LBToken__SelfApproval(address owner);
error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
error LBToken__TransferToSelf();

/** LBFactory errors */

error LBFactory__IdenticalAddresses(IERC20 token);
error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
error LBFactory__AddressZero();
error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
error LBFactory__DecreasingPeriods(uint16 filterPeriod, uint16 decayPeriod);
error LBFactory__ReductionFactorOverflows(uint16 reductionFactor, uint256 max);
error LBFactory__VariableFeeControlOverflows(uint16 variableFeeControl, uint256 max);
error LBFactory__BaseFeesBelowMin(uint256 baseFees, uint256 minBaseFees);
error LBFactory__FeesAboveMax(uint256 fees, uint256 maxFees);
error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
error LBFactory__BinStepRequirementsBreached(uint256 lowerBound, uint16 binStep, uint256 higherBound);
error LBFactory__ProtocolShareOverflows(uint16 protocolShare, uint256 max);
error LBFactory__FunctionIsLockedForUsers(address user);
error LBFactory__FactoryLockIsAlreadyInTheSameState();
error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
error LBFactory__BinStepHasNoPreset(uint256 binStep);
error LBFactory__SameFeeRecipient(address feeRecipient);
error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
error LBFactory__SameImplementation(address LBPairImplementation);
error LBFactory__ImplementationNotSet();

/** LBPair errors */

error LBPair__InsufficientAmounts();
error LBPair__AddressZero();
error LBPair__AddressZeroOrThis();
error LBPair__CompositionFactorFlawed(uint256 id);
error LBPair__InsufficientLiquidityMinted(uint256 id);
error LBPair__InsufficientLiquidityBurned(uint256 id);
error LBPair__WrongLengths();
error LBPair__OnlyStrictlyIncreasingId();
error LBPair__OnlyFactory();
error LBPair__DistributionsOverflow();
error LBPair__OnlyFeeRecipient(address feeRecipient, address sender);
error LBPair__OracleNotEnoughSample();
error LBPair__AlreadyInitialized();
error LBPair__OracleNewSizeTooSmall(uint256 newSize, uint256 oracleSize);
error LBPair__FlashLoanCallbackFailed();
error LBPair__FlashLoanInvalidBalance();
error LBPair__FlashLoanInvalidToken();

/** BinHelper errors */

error BinHelper__BinStepOverflows(uint256 bp);
error BinHelper__IdOverflows();

/** Math128x128 errors */

error Math128x128__PowerUnderflow(uint256 x, int256 y);
error Math128x128__LogUnderflow();

/** Math512Bits errors */

error Math512Bits__MulDivOverflow(uint256 prod1, uint256 denominator);
error Math512Bits__ShiftDivOverflow(uint256 prod1, uint256 denominator);
error Math512Bits__MulShiftOverflow(uint256 prod1, uint256 offset);
error Math512Bits__OffsetOverflows(uint256 offset);

/** Oracle errors */

error Oracle__AlreadyInitialized(uint256 _index);
error Oracle__LookUpTimestampTooOld(uint256 _minTimestamp, uint256 _lookUpTimestamp);
error Oracle__NotInitialized();

/** PendingOwnable errors */

error PendingOwnable__NotOwner();
error PendingOwnable__NotPendingOwner();
error PendingOwnable__PendingOwnerAlreadySet();
error PendingOwnable__NoPendingOwner();
error PendingOwnable__AddressZero();

/** ReentrancyGuardUpgradeable errors */

error ReentrancyGuardUpgradeable__ReentrantCall();
error ReentrancyGuardUpgradeable__AlreadyInitialized();

/** SafeCast errors */

error SafeCast__Exceeds256Bits(uint256 x);
error SafeCast__Exceeds248Bits(uint256 x);
error SafeCast__Exceeds240Bits(uint256 x);
error SafeCast__Exceeds232Bits(uint256 x);
error SafeCast__Exceeds224Bits(uint256 x);
error SafeCast__Exceeds216Bits(uint256 x);
error SafeCast__Exceeds208Bits(uint256 x);
error SafeCast__Exceeds200Bits(uint256 x);
error SafeCast__Exceeds192Bits(uint256 x);
error SafeCast__Exceeds184Bits(uint256 x);
error SafeCast__Exceeds176Bits(uint256 x);
error SafeCast__Exceeds168Bits(uint256 x);
error SafeCast__Exceeds160Bits(uint256 x);
error SafeCast__Exceeds152Bits(uint256 x);
error SafeCast__Exceeds144Bits(uint256 x);
error SafeCast__Exceeds136Bits(uint256 x);
error SafeCast__Exceeds128Bits(uint256 x);
error SafeCast__Exceeds120Bits(uint256 x);
error SafeCast__Exceeds112Bits(uint256 x);
error SafeCast__Exceeds104Bits(uint256 x);
error SafeCast__Exceeds96Bits(uint256 x);
error SafeCast__Exceeds88Bits(uint256 x);
error SafeCast__Exceeds80Bits(uint256 x);
error SafeCast__Exceeds72Bits(uint256 x);
error SafeCast__Exceeds64Bits(uint256 x);
error SafeCast__Exceeds56Bits(uint256 x);
error SafeCast__Exceeds48Bits(uint256 x);
error SafeCast__Exceeds40Bits(uint256 x);
error SafeCast__Exceeds32Bits(uint256 x);
error SafeCast__Exceeds24Bits(uint256 x);
error SafeCast__Exceeds16Bits(uint256 x);
error SafeCast__Exceeds8Bits(uint256 x);

/** TreeMath errors */

error TreeMath__ErrorDepthSearch();

/** JoeLibrary errors */

error JoeLibrary__IdenticalAddresses();
error JoeLibrary__AddressZero();
error JoeLibrary__InsufficientAmount();
error JoeLibrary__InsufficientLiquidity();

/** TokenHelper errors */

error TokenHelper__NonContract();
error TokenHelper__CallFailed();
error TokenHelper__TransferFailed();

/** LBQuoter errors */

error LBQuoter_InvalidLength();