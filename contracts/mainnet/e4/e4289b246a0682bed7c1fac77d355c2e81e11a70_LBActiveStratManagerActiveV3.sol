// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "openzeppelin/access/Ownable.sol";
import "joe-v2/interfaces/ILBPair.sol";
import "../interfaces/ILBStrategy.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/// @title LBActiveStratManager V3.1
/// @author SteakHut Finance
/// @notice contract to enable rebalances of the underlying strategy using existing parameters include helpers around volatility
/// @notice this strategy will chase an active bin once it goes within x number bins of current range
/// @notice this strategy will also perform a rebalance once it becomes one sided
contract LBActiveStratManagerActiveV3 is
    Ownable,
    AutomationCompatibleInterface
{
    using SafeERC20 for IERC20;
    address public immutable strategyAddress;
    uint256 public binOffset;

    //tracks rebalances and attempts to ~equal weight on next rebalance
    bool public isTokenXWeighted;
    bool public isTokenYWeighted;
    uint256 public centerOffset;

    //harvesting params
    uint256 public lastHarvestTimestamp;
    uint256 public harvestDelay = 21600; //6 hours

    //rebalance params
    uint256 public rebalanceDelay = 3 days; //3 days
    uint256 public rebalanceTimestamp;
    bool public isPendingRebalance;

    /// -----------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------

    constructor(
        address _strategyAddress,
        uint256 _binOffset,
        uint256 _centerOffset
    ) {
        strategyAddress = _strategyAddress;
        binOffset = _binOffset;
        centerOffset = _centerOffset;
    }

    /// -----------------------------------------------------------
    /// View / Pure Functions
    /// -----------------------------------------------------------

    /// @notice returns the minimum and maximum bin currently used by the underlying strategy
    function _checkMinMaxActiveBins(
        uint256[] memory activeBins
    ) public pure returns (uint256 minBin, uint256 maxBin) {
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
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        //fetch all the active bins in the strategy
        uint256[] memory activeBins = ILBStrategy(strategyAddress)
            .strategyActiveBins();
        (uint256 minBin, uint256 maxBin) = _checkMinMaxActiveBins(activeBins);

        //get the center of the active bins
        uint256 binLength = activeBins.length;
        uint256 centerBin = binLength / 2;
        uint256 minCenterBin = activeBins[centerBin - centerOffset];
        uint256 maxCenterBin = activeBins[centerBin + centerOffset];

        //fetch the current activeId of the lb pair
        address _lbPair = ILBStrategy(strategyAddress).lbPair();
        uint256 activeId = ILBPair(_lbPair).getActiveId();

        ///CHECK REBALANCE CASES
        if (isPendingRebalance && rebalanceTimestamp != 0) {
            //check enough time has passed
            if (block.timestamp >= rebalanceTimestamp + rebalanceDelay) {
                ////////
                upkeepNeeded = true;
            }
        }
        //if the strategy has come back into range remove the volatility params
        else if (
            (isPendingRebalance &&
                activeId >= minBin + binOffset &&
                activeId <= maxBin - binOffset)
        ) {
            upkeepNeeded = true;
        }
        //else if the strategy is lopsided we should try to balance towards the center
        else if (
            (activeId <= minCenterBin && isTokenYWeighted) ||
            (activeId >= maxCenterBin && isTokenXWeighted)
        ) {
            upkeepNeeded = true;
        }
        //else if the strategy is near to going out of range start the time rebalance flow
        else if (
            activeId <= minBin + binOffset || activeId >= maxBin - binOffset
        ) {
            upkeepNeeded = true;
        } else if (block.timestamp >= lastHarvestTimestamp + harvestDelay) {
            //a harvest is needed only
            upkeepNeeded = true;
        }
    }

    /// @notice Chainlink Perform Upkeep Function
    /// @notice moves liquidity around the active bin once binOffset is achieved
    /// @notice harvest if enough time has passed to perform a harvest only
    function performUpkeep(bytes calldata) external override {
        //fetch all the active bins in the strategy
        uint256[] memory activeBins = ILBStrategy(strategyAddress)
            .strategyActiveBins();
        (uint256 minBin, uint256 maxBin) = _checkMinMaxActiveBins(activeBins);

        //get the center of the active bins
        uint256 binLength = activeBins.length;
        uint256 centerBin = binLength / 2;
        uint256 minCenterBin = activeBins[centerBin - centerOffset];
        uint256 maxCenterBin = activeBins[centerBin + centerOffset];

        //fetch the current activeId of the lb pair
        address _lbPair = ILBStrategy(strategyAddress).lbPair();
        uint256 activeId = ILBPair(_lbPair).getActiveId();

        ///CHECK REBALANCE CASES
        if (isPendingRebalance && rebalanceTimestamp != 0) {
            //check enough time has passed
            if (block.timestamp >= rebalanceTimestamp + rebalanceDelay) {
                ////////
                ////////out of range and enough delay has passed

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
                //execute the rebalance
                _rebalance();
            }
        }
        //if the strategy has come back into range remove the volatility params
        else if (
            (isPendingRebalance &&
                activeId >= minBin + binOffset &&
                activeId <= maxBin - binOffset)
        ) {
            //reset volatitlity params
            rebalanceTimestamp = 0;
            isPendingRebalance = false;
        }
        //else if the strategy is lopsided we should try to balance towards the center
        else if (
            (activeId <= minCenterBin && isTokenYWeighted) ||
            (activeId >= maxCenterBin && isTokenXWeighted)
        ) {
            //reset the weighting switch
            isTokenYWeighted = false;
            isTokenXWeighted = false;

            //harvest pending rewards
            _harvest();

            //rebalance keeping the same parameters as before
            _rebalance();
        }
        //else if the strategy is near to going out of range start the time rebalance flow
        else if (
            activeId <= minBin + binOffset || activeId >= maxBin - binOffset
        ) {
            //start pending rebalance timer
            rebalanceTimestamp = block.timestamp;
            isPendingRebalance = true;
        } else if (block.timestamp >= lastHarvestTimestamp + harvestDelay) {
            //a harvest is needed only
            _harvest();
        }
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

    /// @notice Updates the minimum period between harvests
    /// @param _period new minimum period.
    function setPeriod(uint256 _period) external onlyOwner {
        require(_period > 3600, "Manager: Period too small");
        harvestDelay = _period;
    }

    /// @notice Updates the minimum period between rebalancing
    /// @param _period new minimum period.
    function setRebalancePeriod(uint256 _period) external onlyOwner {
        require(_period > 3600, "Manager: Period too small");
        rebalanceDelay = _period;
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

        //harvest pending rewards
        ILBStrategy(strategyAddress).harvest();

        //execute the rebalance
        ILBStrategy(strategyAddress).executeRebalance();
    }

    /// -----------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------

    function _rebalance() internal {
        //rebalance keeping the same parameters as before
        ILBStrategy(strategyAddress).executeRebalance();

        //reset params
        rebalanceTimestamp = 0;
        isPendingRebalance = false;
    }

    /// @notice executes a harvest of the associated strategy
    function _harvest() internal {
        ILBStrategy strategy = ILBStrategy(strategyAddress);
        strategy.harvest();

        //update the last harvest timestamp
        lastHarvestTimestamp = block.timestamp;
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__AlreadyInitialized();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function forceDecay() external;
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

    function performanceFee() external view returns (uint _performanceFee);

    function steakHutFee() external view returns (uint _performanceFee);

    function MAX_FEE() external view returns (uint MAX_FEE);

    function STRATEGIST_FEE() external view returns (uint);

    function callFee() external view returns (uint);

    function deltaIds() external view returns (int256[] memory deltaIds);

    function distributionX()
        external
        view
        returns (uint256[] memory distributionX);

    function distributionY()
        external
        view
        returns (uint256[] memory distributionY);

    function resetPendingFeeBins() external;

    function idSlippage() external view returns (uint256);

    function vault() external view returns (address);

    function lbPair() external view returns (address);

    function feeRecipient() external view returns (address);

    function strategist() external view returns (address);

    function lbToken() external view returns (address);

    function setKeeper(address _keeper) external;

    function keeper() external view returns (address);

    function strategyPendingFeeBins()
        external
        view
        returns (uint256[] memory pendingFeeBins);

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

    //function harvest() external;

    function harvest()
        external
        returns (uint256 amountXReceived, uint256 amountYReceived);

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory is IPendingOwnable {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

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
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
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
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

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
        uint24 maxVolatilityAccumulator
    ) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

/**
 * @title Liquidity Book Pending Ownable Interface
 * @author Trader Joe
 * @notice Required interface of Pending Ownable contract used for LBFactory
 */
interface IPendingOwnable {
    error PendingOwnable__AddressZero();
    error PendingOwnable__NoPendingOwner();
    error PendingOwnable__NotOwner();
    error PendingOwnable__NotPendingOwner();
    error PendingOwnable__PendingOwnerAlreadySet();

    event PendingOwnerSet(address indexed pendingOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}